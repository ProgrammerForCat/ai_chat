class UsersController < Sinatra::Base
  before do
    content_type :json
    headers 'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
            'Access-Control-Allow-Headers' => 'Content-Type, Authorization'
  end

  options '/*' do
    200
  end

  helpers do
    def authenticate_user!
      token = request.env['HTTP_AUTHORIZATION']&.sub(/^Bearer /, '')
      return halt 401, { error: 'No token provided' }.to_json unless token

      begin
        payload = JWT.decode(token, ENV['JWT_SECRET'], true, { algorithm: 'HS256' })[0]
        @current_user = User[payload['user_id']]
        halt 401, { error: 'Invalid token' }.to_json unless @current_user
      rescue JWT::DecodeError
        halt 401, { error: 'Invalid token' }.to_json
      end
    end
  end

  get '/profile' do
    authenticate_user!
    @current_user.to_json_safe.to_json
  end

  put '/profile' do
    authenticate_user!
    
    begin
      data = JSON.parse(request.body.read)
      
      if data['username']
        @current_user.username = data['username']
      end
      
      if data['gemini_api_key']
        @current_user.gemini_api_key = data['gemini_api_key']
      end
      
      @current_user.save
      
      { success: true, user: @current_user.to_json_safe }.to_json
    rescue JSON::ParserError
      halt 400, { error: 'Invalid JSON' }.to_json
    rescue Sequel::ValidationFailed => e
      halt 400, { error: e.message }.to_json
    rescue => e
      puts "Error updating profile: #{e.message}"
      halt 500, { error: 'Internal server error' }.to_json
    end
  end
end