require_relative '../models/message'
require_relative '../services/gemini_service'

class MessagesController
  def self.create(user, conversation_id, content)
    conversation = user.conversations_dataset.where(id: conversation_id).first
    return { success: false, errors: ['Conversation not found'] } unless conversation
    
    # Save user message
    user_message = Message.create(
      conversation_id: conversation.id,
      role: 'user',
      content: content.strip
    )
    
    unless user_message.valid?
      return { success: false, errors: user_message.errors.full_messages }
    end
    
    # Generate AI response
    messages_for_ai = conversation.messages.map do |msg|
      { role: msg.role, content: msg.content }
    end
    
    gemini_service = GeminiService.new(conversation.specialist_type, user.gemini_api_key)
    ai_response = gemini_service.generate_response(messages_for_ai)
    
    # Save AI response
    ai_message = Message.create(
      conversation_id: conversation.id,
      role: 'assistant',
      content: ai_response
    )
    
    unless ai_message.valid?
      return { success: false, errors: ai_message.errors.full_messages }
    end
    
    # Update conversation title if needed
    if conversation.messages.count == 2 # First exchange
      update_conversation_title(conversation, content)
    end
    
    {
      success: true,
      messages: [user_message.to_json_safe, ai_message.to_json_safe]
    }
  rescue => e
    puts "Error creating message: #{e.message}"
    { success: false, errors: ['Failed to send message'] }
  end
  
  private
  
  def self.update_conversation_title(conversation, user_content)
    # Generate a short title from user's first message
    title = user_content.split(/[。．\n]/).first&.strip
    title = title[0..30] + '...' if title && title.length > 30
    title = title || "新しい相談"
    
    conversation.update(title: title)
  rescue => e
    puts "Error updating conversation title: #{e.message}"
  end
end