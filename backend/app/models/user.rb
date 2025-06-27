class User < ApplicationRecord
  has_secure_password
  
  has_many :conversations, dependent: :destroy
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, on: :create
  
  def to_json_safe
    {
      id: id,
      email: email,
      username: username,
      gemini_api_key: gemini_api_key,
      created_at: created_at
    }
  end
end