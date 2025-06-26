require 'sinatra'
require 'sinatra/json'
require 'sinatra/cross_origin'
require 'sequel'

# Enable CORS
configure do
  enable :cross_origin
end

before do
  response.headers['Access-Control-Allow-Origin'] = 'http://localhost:8080'
  response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
  response.headers['Access-Control-Allow-Headers'] = 'Authorization, Content-Type'
  response.headers['Access-Control-Allow-Credentials'] = 'true'
end

# Database setup FIRST
DB = Sequel.connect(ENV['DATABASE_URL'] || 'postgres://postgres:password@db:5432/ai_chat_development')


# Create tables if they don't exist
DB.create_table? :users do
  primary_key :id, type: :Bignum
  String :email, null: false, unique: true
  String :password_digest, null: false
  DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
end

DB.create_table? :conversations do
  primary_key :id, type: :Bignum
  foreign_key :user_id, :users, null: false
  String :specialist_type, null: false
  String :title
  DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
end

DB.create_table? :messages do
  primary_key :id, type: :Bignum
  foreign_key :conversation_id, :conversations, null: false
  String :role, null: false
  Text :content, null: false
  DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
end

# Load models AFTER database connection
require_relative 'models/user'
require_relative 'models/conversation'
require_relative 'models/message'

# Load controllers
require_relative 'controllers/auth_controller'
require_relative 'controllers/conversations_controller'
require_relative 'controllers/messages_controller'

# Load services
require_relative 'services/gemini_service'

# Helper method for authentication
def authenticate_user
  auth_header = request.env['HTTP_AUTHORIZATION']
  current_user = AuthController.authenticate_request(auth_header)
  
  unless current_user
    halt 401, json({ error: 'Unauthorized' })
  end
  
  current_user
end

# Routes

# Health check
get '/health' do
  json({ status: 'ok', timestamp: Time.now })
end

# OPTIONS requests for CORS preflight
options '*' do
  response.headers['Access-Control-Allow-Origin'] = 'http://localhost:8080'
  response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
  response.headers['Access-Control-Allow-Headers'] = 'Authorization, Content-Type'
  200
end

# Authentication routes
post '/api/v1/auth/register' do
  content_type :json
  
  data = JSON.parse(request.body.read)
  user_data = data['user']
  result = AuthController.register(user_data['email'], user_data['password'])
  
  if result[:success]
    status 201
    json({
      message: 'User registered successfully',
      user: result[:user],
      token: result[:token]
    })
  else
    status 400
    json({ errors: result[:errors] })
  end
end

post '/api/v1/auth/login' do
  content_type :json
  
  data = JSON.parse(request.body.read)
  result = AuthController.login(data['email'], data['password'])
  
  if result[:success]
    json({
      message: 'Login successful',
      user: result[:user],
      token: result[:token]
    })
  else
    status 401
    json({ error: result[:errors].join(', ') })
  end
end

delete '/api/v1/auth/logout' do
  content_type :json
  json({ message: 'Logged out successfully' })
end

# Protected routes - require authentication

# Specialists endpoint
get '/api/v1/specialists' do
  content_type :json
  authenticate_user
  
  specialists = [
    {
      id: 'psychologist',
      name: '心理カウンセラー',
      description: '心の悩みや人間関係の相談に対応します',
      icon: '🧠'
    },
    {
      id: 'career',
      name: 'キャリアアドバイザー',
      description: '転職や昇進、スキルアップの相談に対応します',
      icon: '💼'
    },
    {
      id: 'health',
      name: '健康アドバイザー',
      description: '健康管理や生活習慣の相談に対応します',
      icon: '🏥'
    },
    {
      id: 'legal',
      name: '法律アドバイザー',
      description: '法的な問題や手続きの相談に対応します',
      icon: '⚖️'
    },
    {
      id: 'finance',
      name: '金融アドバイザー',
      description: '資産運用や家計管理の相談に対応します',
      icon: '💰'
    }
  ]
  
  json({ specialists: specialists })
end

# Conversations routes
get '/api/v1/conversations' do
  content_type :json
  current_user = authenticate_user
  
  conversations = ConversationsController.index(current_user)
  json({ conversations: conversations })
end

get '/api/v1/conversations/:id' do
  content_type :json
  current_user = authenticate_user
  
  conversation = ConversationsController.show(current_user, params[:id])
  
  if conversation
    json({ conversation: conversation })
  else
    status 404
    json({ error: 'Conversation not found' })
  end
end

post '/api/v1/conversations' do
  content_type :json
  current_user = authenticate_user
  
  data = JSON.parse(request.body.read)
  conversation_data = data['conversation']
  
  result = ConversationsController.create(
    current_user,
    conversation_data['specialist_type'],
    conversation_data['title']
  )
  
  if result[:success]
    status 201
    json({
      message: 'Conversation created successfully',
      conversation: result[:conversation]
    })
  else
    status 400
    json({ errors: result[:errors] })
  end
end

# Messages routes
post '/api/v1/conversations/:conversation_id/messages' do
  content_type :json
  current_user = authenticate_user
  
  data = JSON.parse(request.body.read)
  message_data = data['message']
  
  result = MessagesController.create(
    current_user,
    params[:conversation_id],
    message_data['content']
  )
  
  if result[:success]
    status 201
    json({
      message: 'Message sent successfully',
      messages: result[:messages]
    })
  else
    status 400
    json({ errors: result[:errors] })
  end
end

# Error handling
error 404 do
  content_type :json
  json({ error: 'Not found' })
end

error 500 do
  content_type :json
  json({ error: 'Internal server error' })
end