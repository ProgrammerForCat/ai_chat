require 'jwt'
require_relative '../models/user'

class AuthController
  SECRET_KEY = ENV['JWT_SECRET'] || 'your-secret-key'
  
  def self.register(email, password)
    return { success: false, errors: ['Email and password are required'] } if email.nil? || password.nil?
    
    user = User.new(email: email.downcase.strip)
    user.password = password
    
    if user.valid?
      user.save
      token = generate_token(user.id)
      { success: true, user: user.to_json_safe, token: token }
    else
      { success: false, errors: user.errors.full_messages }
    end
  rescue Sequel::UniqueConstraintViolation
    { success: false, errors: ['Email already exists'] }
  rescue => e
    puts "Registration error: #{e.message}"
    { success: false, errors: ['Registration failed'] }
  end
  
  def self.login(email, password)
    return { success: false, errors: ['Email and password are required'] } if email.nil? || password.nil?
    
    user = User.first(email: email.downcase.strip)
    
    if user&.authenticate(password)
      token = generate_token(user.id)
      { success: true, user: user.to_json_safe, token: token }
    else
      { success: false, errors: ['Invalid email or password'] }
    end
  rescue => e
    puts "Login error: #{e.message}"
    { success: false, errors: ['Login failed'] }
  end
  
  def self.authenticate_request(auth_header)
    return nil unless auth_header&.start_with?('Bearer ')
    
    token = auth_header.split(' ').last
    decoded = JWT.decode(token, SECRET_KEY, true, { algorithm: 'HS256' })
    user_id = decoded[0]['user_id']
    User[user_id]
  rescue JWT::DecodeError => e
    puts "JWT decode error: #{e.message}"
    nil
  rescue => e
    puts "Authentication error: #{e.message}"
    nil
  end
  
  private
  
  def self.generate_token(user_id)
    payload = {
      user_id: user_id,
      exp: Time.now.to_i + (24 * 60 * 60) # 24 hours
    }
    JWT.encode(payload, SECRET_KEY, 'HS256')
  end
end