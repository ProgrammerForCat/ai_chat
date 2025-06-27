class Api::V1::ConversationsController < ApplicationController
  before_action :require_authentication
  
  def index
    conversations = current_user.conversations.order(created_at: :desc)
    render json: { conversations: conversations.map(&:to_json_list) }
  rescue => e
    Rails.logger.error "Error fetching conversations: #{e.message}"
    render json: { conversations: [] }, status: :internal_server_error
  end
  
  def show
    conversation = current_user.conversations.find_by(id: params[:id])
    return render json: { error: 'Conversation not found' }, status: :not_found unless conversation
    
    render json: { conversation: conversation.to_json_safe }
  rescue => e
    Rails.logger.error "Error fetching conversation: #{e.message}"
    render json: { error: 'Failed to fetch conversation' }, status: :internal_server_error
  end
  
  def create
    # Support both nested and flat parameter structures
    specialist_type = params[:specialist_type] || params.dig(:conversation, :specialist_type)
    title = params[:title] || params.dig(:conversation, :title)
    
    Rails.logger.info "Creating conversation with specialist_type: #{specialist_type}, title: #{title}"
    
    conversation = current_user.conversations.build(
      specialist_type: specialist_type,
      title: title || generate_title(specialist_type)
    )
    
    if conversation.save
      Rails.logger.info "Conversation created successfully: #{conversation.id}"
      render json: { success: true, conversation: conversation.to_json_safe }
    else
      Rails.logger.error "Failed to save conversation: #{conversation.errors.full_messages}"
      render json: { success: false, errors: conversation.errors.full_messages }
    end
  rescue => e
    Rails.logger.error "Error creating conversation: #{e.message}"
    render json: { success: false, errors: ['Failed to create conversation'] }
  end
  
  private
  
  def generate_title(specialist_type)
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