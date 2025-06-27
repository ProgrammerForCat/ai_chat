class Api::V1::UsersController < ApplicationController
  before_action :require_authentication
  
  def profile
    render json: { user: current_user.to_json_safe }
  end
  
  def update_profile
    if params.key?(:username)
      current_user.username = params[:username]
    end
    
    if params.key?(:gemini_api_key)
      current_user.gemini_api_key = params[:gemini_api_key]
    end
    
    if current_user.save
      render json: { success: true, user: current_user.to_json_safe }
    else
      render json: { success: false, errors: current_user.errors.full_messages }, status: :bad_request
    end
  rescue => e
    Rails.logger.error "Error updating profile: #{e.message}"
    render json: { success: false, errors: ['Failed to update profile'] }, status: :internal_server_error
  end

  def update_password
    if !current_user.authenticate(params[:current_password])
      return render json: { success: false, errors: ['現在のパスワードが正しくありません'] }, status: :bad_request
    end

    if params[:new_password] != params[:new_password_confirmation]
      return render json: { success: false, errors: ['新しいパスワードと確認用パスワードが一致しません'] }, status: :bad_request
    end

    if current_user.update(password: params[:new_password])
      render json: { success: true, message: 'パスワードが正常に更新されました' }
    else
      render json: { success: false, errors: current_user.errors.full_messages }, status: :bad_request
    end
  rescue => e
    Rails.logger.error "Error updating password: #{e.message}"
    render json: { success: false, errors: ['パスワードの更新に失敗しました'] }, status: :internal_server_error
  end
end