class Message < ApplicationRecord
  belongs_to :conversation
  
  validates :conversation_id, presence: true
  validates :role, presence: true, inclusion: { in: ['user', 'assistant'] }
  validates :content, presence: true
  
  def to_json_safe
    {
      id: id,
      conversation_id: conversation_id,
      role: role,
      content: content,
      created_at: created_at
    }
  end
end