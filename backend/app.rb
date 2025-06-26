require 'sinatra'
require 'sinatra/json'
require 'sinatra/cross_origin'
require 'sequel'
require 'bcrypt'
require 'jwt'
require 'httparty'

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

# Database setup
DB = Sequel.connect(ENV['DATABASE_URL'] || 'postgres://postgres:password@db:5432/ai_chat_development')

# Create UUID extension if not exists
begin
  DB.run 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'
rescue => e
  puts "UUID extension already exists or couldn't be created: #{e.message}"
end

# Create tables if they don't exist
DB.create_table? :users do
  primary_key :id
  String :email, null: false, unique: true
  String :password_digest, null: false
  DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
end

DB.create_table? :conversations do
  primary_key :id
  foreign_key :user_id, :users, null: false
  String :specialist_type, null: false
  String :title
  DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
end

DB.create_table? :messages do
  primary_key :id
  foreign_key :conversation_id, :conversations, null: false
  String :role, null: false
  Text :content, null: false
  DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
end

# Models
class User < Sequel::Model
  include BCrypt
  
  one_to_many :conversations
  
  def password
    @password ||= Password.new(password_digest)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.password_digest = @password
  end
  
  def authenticate(plain_password)
    password == plain_password
  end
end

class Conversation < Sequel::Model
  many_to_one :user
  one_to_many :messages
  
  def display_title
    title || messages.first&.fetch(:content, "新しい相談")&.slice(0, 50)
  end
end

class Message < Sequel::Model
  many_to_one :conversation
end

# Gemini Service
class GeminiService
  def initialize(specialist_type)
    @specialist_type = specialist_type
    @api_key = ENV['GEMINI_API_KEY']
    @api_url = "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent"
  end
  
  def generate_response(messages)
    system_prompt = get_system_prompt(@specialist_type)
    formatted_contents = format_messages(messages, system_prompt)
    
    response = make_api_request(formatted_contents)
    
    if response && response['candidates'] && response['candidates'][0]
      candidate = response['candidates'][0]
      content = candidate['content']
      
      puts "Candidate content: #{content.inspect}"
      
      if content && content['parts'] && content['parts'][0] && content['parts'][0]['text']
        content['parts'][0]['text']
      elsif candidate['finishReason'] == 'MAX_TOKENS'
        "申し訳ございませんが、回答が長すぎるため途中で切れてしまいました。より具体的な質問をしていただけますでしょうか。"
      else
        get_fallback_response(@specialist_type)
      end
    else
      get_fallback_response(@specialist_type)
    end
  rescue => e
    puts "Gemini API Error: #{e.message}"
    get_fallback_response(@specialist_type)
  end
  
  private
  
  def make_api_request(contents)
    puts "Making Gemini API request..."
    puts "API URL: #{@api_url}?key=#{@api_key[0..10]}..."
    puts "Contents: #{contents.inspect}"
    
    response = HTTParty.post(
      "#{@api_url}?key=#{@api_key}",
      body: {
        contents: contents,
        generationConfig: {
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 2048,
        }
      }.to_json,
      headers: {
        'Content-Type' => 'application/json'
      }
    )
    
    puts "Response status: #{response.code}"
    puts "Response body: #{response.body}"
    
    if response.success?
      response.parsed_response
    else
      puts "API request failed with status: #{response.code}"
      nil
    end
  end
  
  def get_system_prompt(specialist_type)
    case specialist_type
    when 'lawyer'
      "あなたはIT弁護士として行動してください。ITや技術に関連する法的問題について、専門的で分かりやすいアドバイスを提供してください。"
    when 'career_consultant'
      "あなたはキャリアコンサルタントとして行動してください。転職、キャリア開発、スキルアップなどについて、実践的で建設的なアドバイスを提供してください。"
    when 'psychologist'
      "あなたは心理カウンセラーとして行動してください。メンタルヘルス、ストレス管理、人間関係の悩みなどについて、共感的で支援的な対応を提供してください。"
    else
      "あなたは専門的なアドバイザーとして、相談者の質問に対して親切で有益な回答を提供してください。"
    end
  end
  
  def format_messages(messages, system_prompt)
    contents = []
    
    if messages.any?
      first_content = "#{system_prompt}\n\n#{messages.first[:content]}"
      contents << {
        role: 'user',
        parts: [{ text: first_content }]
      }
      
      messages.drop(1).each do |message|
        contents << {
          role: message[:role] == 'user' ? 'user' : 'model',
          parts: [{ text: message[:content] }]
        }
      end
    end
    
    contents
  end
  
  def get_fallback_response(specialist_type)
    "申し訳ございませんが、現在システムに一時的な問題が発生しております。改めてご相談内容をお聞かせください。"
  end
end

# Helper methods
def authenticate_user!
  token = request.env['HTTP_AUTHORIZATION']&.split(' ')&.last
  
  if token
    begin
      decoded_token = JWT.decode(token, ENV['SECRET_KEY_BASE'] || 'default_secret', true, { algorithm: 'HS256' })
      @current_user = User[decoded_token[0]['user_id']]
    rescue JWT::DecodeError, Sequel::NoMatchingRow => e
      halt 401, json({ error: 'Unauthorized' })
    end
  else
    halt 401, json({ error: 'Unauthorized' })
  end
end

def generate_token(user)
  JWT.encode({ user_id: user.id, exp: (Time.now + 24*60*60).to_i }, ENV['SECRET_KEY_BASE'] || 'default_secret', 'HS256')
end

# Routes
options '*' do
  response.headers["Access-Control-Allow-Origin"] = "http://localhost:8080"
  response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type"
  response.headers["Access-Control-Allow-Credentials"] = "true"
  200
end

# Authentication
post '/api/v1/auth/register' do
  data = JSON.parse(request.body.read)
  user_data = data['user']
  
  begin
    # Check if user already exists
    existing_user = User.first(email: user_data['email'])
    if existing_user
      status 422
      return json({ errors: ['Email already exists'] })
    end
    
    # Create password hash
    password_hash = BCrypt::Password.create(user_data['password'])
    
    user = User.create(
      email: user_data['email'],
      password_digest: password_hash
    )
    
    token = generate_token(user)
    json({
      user: { id: user.id, email: user.email },
      token: token
    })
  rescue => e
    status 422
    json({ errors: [e.message] })
  end
end

post '/api/v1/auth/login' do
  data = JSON.parse(request.body.read)
  user = User.first(email: data['email'])
  
  if user && user.authenticate(data['password'])
    token = generate_token(user)
    json({
      user: { id: user.id, email: user.email },
      token: token
    })
  else
    status 401
    json({ error: 'Invalid email or password' })
  end
end

delete '/api/v1/auth/logout' do
  json({ message: 'Logged out successfully' })
end

# Specialists
get '/api/v1/specialists' do
  authenticate_user!
  
  specialists = [
    {
      id: 'lawyer',
      name: 'IT弁護士AI',
      description: 'ITに関する法的問題について相談できます',
      icon: '⚖️'
    },
    {
      id: 'career_consultant',
      name: 'キャリアコンサルタントAI',
      description: 'キャリアや転職に関する相談ができます',
      icon: '💼'
    },
    {
      id: 'psychologist',
      name: '心理カウンセラーAI',
      description: 'メンタルヘルスや心の悩みについて相談できます',
      icon: '🧠'
    }
  ]
  
  json({ specialists: specialists })
end

# Conversations
get '/api/v1/conversations' do
  authenticate_user!
  
  conversations = @current_user.conversations_dataset.order(Sequel.desc(:created_at)).all
  
  json({
    conversations: conversations.map do |conv|
      {
        id: conv.id,
        title: conv.display_title,
        specialist_type: conv.specialist_type,
        created_at: conv.created_at,
        message_count: conv.messages.count
      }
    end
  })
end

get '/api/v1/conversations/:id' do
  authenticate_user!
  
  conversation = @current_user.conversations_dataset.first(id: params[:id])
  halt 404, json({ error: 'Conversation not found' }) unless conversation
  
  messages = conversation.messages_dataset.order(:created_at).all
  
  json({
    conversation: {
      id: conversation.id,
      title: conversation.display_title,
      specialist_type: conversation.specialist_type,
      created_at: conversation.created_at,
      messages: messages.map do |msg|
        {
          id: msg.id,
          role: msg.role,
          content: msg.content,
          created_at: msg.created_at
        }
      end
    }
  })
end

post '/api/v1/conversations' do
  authenticate_user!
  
  data = JSON.parse(request.body.read)
  conv_data = data['conversation']
  
  conversation = Conversation.create(
    user_id: @current_user.id,
    specialist_type: conv_data['specialist_type'],
    title: conv_data['title']
  )
  
  json({
    conversation: {
      id: conversation.id,
      title: conversation.display_title,
      specialist_type: conversation.specialist_type,
      created_at: conversation.created_at,
      messages: []
    }
  })
end

# Messages
post '/api/v1/conversations/:conversation_id/messages' do
  authenticate_user!
  
  conversation = @current_user.conversations_dataset.first(id: params[:conversation_id])
  halt 404, json({ error: 'Conversation not found' }) unless conversation
  
  data = JSON.parse(request.body.read)
  
  # Create user message
  user_message = Message.create(
    conversation_id: conversation.id,
    role: 'user',
    content: data['message']['content']
  )
  
  # Generate AI response
  messages = conversation.messages_dataset.order(:created_at).all
  ai_service = GeminiService.new(conversation.specialist_type)
  ai_response = ai_service.generate_response(messages)
  
  # Create assistant message
  assistant_message = Message.create(
    conversation_id: conversation.id,
    role: 'assistant',
    content: ai_response
  )
  
  # Update conversation title if needed
  if conversation.title.nil? && conversation.messages_dataset.where(role: 'user').count == 1
    conversation.update(title: user_message.content[0, 50])
  end
  
  json({
    messages: [
      {
        id: user_message.id,
        role: user_message.role,
        content: user_message.content,
        created_at: user_message.created_at
      },
      {
        id: assistant_message.id,
        role: assistant_message.role,
        content: assistant_message.content,
        created_at: assistant_message.created_at
      }
    ]
  })
end

# Health check
get '/health' do
  json({ status: 'ok', timestamp: Time.now })
end