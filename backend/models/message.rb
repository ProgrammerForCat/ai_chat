require 'sequel'

class Message < Sequel::Model
  plugin :validation_helpers
  plugin :timestamps, update_on_create: true
  
  # Set primary key to UUID string
  set_primary_key :id
  unrestrict_primary_key
  
  many_to_one :conversation
  
  def validate
    super
    validates_presence [:conversation_id, :role, :content]
    validates_includes ['user', 'assistant'], :role
  end
  
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