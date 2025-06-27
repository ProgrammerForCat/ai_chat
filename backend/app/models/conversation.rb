class Conversation < ApplicationRecord
  belongs_to :user
  has_many :messages, -> { order(:created_at) }, dependent: :destroy
  
  validates :user_id, presence: true
  validates :specialist_type, presence: true
  
  def to_json_safe
    {
      id: id,
      user_id: user_id,
      specialist_type: specialist_type,
      title: title,
      created_at: created_at,
      messages: messages.map(&:to_json_safe)
    }
  end
  
  def to_json_list
    {
      id: id,
      specialist_type: specialist_type,
      title: title || "新しい会話",
      created_at: created_at,
      message_count: messages.count
    }
  end
end