require_relative '../models/conversation'
require_relative '../models/message'

class ConversationsController
  def self.index(user)
    conversations = user.conversations_dataset.reverse(:created_at).all
    conversations.map(&:to_json_list)
  rescue => e
    puts "Error fetching conversations: #{e.message}"
    []
  end
  
  def self.show(user, conversation_id)
    conversation = user.conversations_dataset.where(id: conversation_id).first
    return nil unless conversation
    
    conversation.to_json_safe
  rescue => e
    puts "Error fetching conversation: #{e.message}"
    nil
  end
  
  def self.create(user, specialist_type, title = nil)
    conversation = Conversation.create(
      user_id: user.id,
      specialist_type: specialist_type,
      title: title || generate_title(specialist_type)
    )
    
    if conversation.valid?
      { success: true, conversation: conversation.to_json_safe }
    else
      { success: false, errors: conversation.errors.full_messages }
    end
  rescue => e
    puts "Error creating conversation: #{e.message}"
    { success: false, errors: ['Failed to create conversation'] }
  end
  
  private
  
  def self.generate_title(specialist_type)
    specialists = {
      'psychologist' => '心理カウンセラー',
      'career' => 'キャリアアドバイザー',
      'health' => '健康アドバイザー',
      'legal' => '法律アドバイザー',
      'finance' => '金融アドバイザー',
      # Legacy mappings
      'lawyer' => '法律アドバイザー',
      'career_consultant' => 'キャリアアドバイザー'
    }
    
    "#{specialists[specialist_type] || specialist_type}との相談"
  end
end