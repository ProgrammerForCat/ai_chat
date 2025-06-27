class Api::V1::AuthController < ApplicationController
  SECRET_KEY = ENV['JWT_SECRET'] || 'your-secret-key'
  
  def register
    # Support both nested and flat parameter structures
    email = params[:email] || params.dig(:user, :email) || params.dig(:auth, :user, :email)
    password = params[:password] || params.dig(:user, :password) || params.dig(:auth, :user, :password)
    username = params[:username] || params.dig(:user, :username) || params.dig(:auth, :user, :username)
    gemini_api_key = params[:gemini_api_key] || params.dig(:user, :gemini_api_key) || params.dig(:auth, :user, :gemini_api_key)
    
    return render json: { success: false, errors: ['Email and password are required'] } if email.blank? || password.blank?
    
    user = User.new(
      email: email.downcase.strip,
      password: password,
      username: username,
      gemini_api_key: gemini_api_key
    )
    
    if user.save
      token = generate_token(user.id)
      render json: { success: true, user: user.to_json_safe, token: token }
    else
      render json: { success: false, errors: user.errors.full_messages }
    end
  rescue ActiveRecord::RecordNotUnique
    render json: { success: false, errors: ['Email already exists'] }
  rescue => e
    Rails.logger.error "Registration error: #{e.message}"
    render json: { success: false, errors: ['Registration failed'] }
  end
  
  def login
    # Support both nested and flat parameter structures
    email = params[:email] || params.dig(:auth, :email)
    password = params[:password] || params.dig(:auth, :password)
    
    Rails.logger.info "Login attempt for email: #{email}"
    
    return render json: { success: false, errors: ['Email and password are required'] } if email.blank? || password.blank?
    
    user = User.find_by(email: email.downcase.strip)
    Rails.logger.info "User found: #{user.present?}"
    
    if user&.authenticate(password)
      token = generate_token(user.id)
      Rails.logger.info "Login successful for user: #{user.id}"
      render json: { success: true, user: user.to_json_safe, token: token }
    else
      Rails.logger.info "Login failed: Invalid credentials"
      render json: { success: false, errors: ['Invalid email or password'] }
    end
  rescue => e
    Rails.logger.error "Login error: #{e.message}"
    render json: { success: false, errors: ['Login failed'] }
  end
  
  def logout
    render json: { success: true, message: 'Logged out successfully' }
  end
  
  private
  
  def generate_token(user_id)
    payload = {
      user_id: user_id,
      exp: Time.now.to_i + (24 * 60 * 60) # 24 hours
    }
    JWT.encode(payload, SECRET_KEY, 'HS256')
  end
end