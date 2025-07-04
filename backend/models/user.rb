require 'sequel'
require 'bcrypt'

class User < Sequel::Model
  plugin :validation_helpers
  plugin :timestamps, update_on_create: true
  
  
  one_to_many :conversations
  
  def validate
    super
    validates_presence [:email, :password_digest]
    validates_unique :email
    validates_format /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i, :email
  end
  
  def password=(new_password)
    self.password_digest = BCrypt::Password.create(new_password)
  end
  
  def authenticate(password)
    BCrypt::Password.new(self.password_digest) == password
  end
  
  def to_json_safe
    result = {
      id: id,
      email: email,
      created_at: created_at
    }
    
    # Add username if column exists
    result[:username] = self[:username] if columns.include?(:username)
    
    # Add gemini_api_key if column exists
    result[:gemini_api_key] = self[:gemini_api_key] if columns.include?(:gemini_api_key)
    
    result
  end
end