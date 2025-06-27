Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      # Auth routes
      namespace :auth do
        post :register
        post :login
        delete :logout
      end
      
      # User routes
      get 'users/profile', to: 'users#profile'
      put 'users/profile', to: 'users#update_profile'
      
      # Conversation routes
      resources :conversations, only: [:index, :show, :create] do
        resources :messages, only: [:create]
      end
      
      # Specialist types (static data)
      get :specialists, to: 'specialists#index'
    end
  end
end
