class ApplicationController < ActionController::API
  SECRET_KEY = ENV['JWT_SECRET'] || 'your-secret-key'
  
  protected
  
  def authenticate_request
    auth_header = request.headers['Authorization']
    return nil unless auth_header&.start_with?('Bearer ')
    
    token = auth_header.split(' ').last
    decoded = JWT.decode(token, SECRET_KEY, true, { algorithm: 'HS256' })
    user_id = decoded[0]['user_id']
    @current_user = User.find(user_id)
  rescue JWT::DecodeError => e
    Rails.logger.error "JWT decode error: #{e.message}"
    nil
  rescue => e
    Rails.logger.error "Authentication error: #{e.message}"
    nil
  end
  
  def require_authentication
    unless authenticate_request
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
  
  def current_user
    @current_user
  end
end
