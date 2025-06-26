require 'sequel'

class Conversation < Sequel::Model
  plugin :validation_helpers
  plugin :timestamps, update_on_create: true
  
  
  many_to_one :user
  one_to_many :messages, order: :created_at
  
  def validate
    super
    validates_presence [:user_id, :specialist_type]
  end
  
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