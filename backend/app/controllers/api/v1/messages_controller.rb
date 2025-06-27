class Api::V1::MessagesController < ApplicationController
  before_action :require_authentication
  
  def create
    conversation = current_user.conversations.find_by(id: params[:conversation_id])
    return render json: { success: false, errors: ['Conversation not found'] } unless conversation
    
    # Support both nested and flat parameter structures
    content = params[:content] || params.dig(:message, :content)
    
    Rails.logger.info "Creating message with content: #{content.present? ? content[0..50] : 'nil'}"
    
    return render json: { success: false, errors: ['Content is required'] } if content.blank?
    
    # Save user message
    user_message = conversation.messages.build(
      role: 'user',
      content: content.strip
    )
    
    unless user_message.save
      return render json: { success: false, errors: user_message.errors.full_messages }
    end
    
    # Generate AI response
    messages_for_ai = conversation.messages.map do |msg|
      { role: msg.role, content: msg.content }
    end
    
    gemini_service = GeminiService.new(conversation.specialist_type, current_user.gemini_api_key)
    ai_response = gemini_service.generate_response(messages_for_ai)
    
    # Save AI response
    ai_message = conversation.messages.build(
      role: 'assistant',
      content: ai_response
    )
    
    unless ai_message.save
      return render json: { success: false, errors: ai_message.errors.full_messages }
    end
    
    # Update conversation title if needed
    if conversation.messages.count == 2 # First exchange
      update_conversation_title(conversation, content)
    end
    
    render json: {
      success: true,
      messages: [user_message.to_json_safe, ai_message.to_json_safe]
    }
  rescue => e
    Rails.logger.error "Error creating message: #{e.message}"
    render json: { success: false, errors: ['Failed to send message'] }
  end
  
  private
  
  def update_conversation_title(conversation, user_content)
    # Generate a short title from user's first message
    title = user_content.split(/[。．\n]/).first&.strip
    title = title[0..30] + '...' if title && title.length > 30
    title = title || "新しい相談"
    
    conversation.update(title: title)
  rescue => e
    Rails.logger.error "Error updating conversation title: #{e.message}"
  end
end