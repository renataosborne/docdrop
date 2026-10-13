Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resource :registration, only: %i[ new create ]

  resources :document_requests, path: "requests", except: :index do
    resource :upload_link, only: [] do
      post :enable
      post :disable
      post :reset
    end

    resources :checklist_items, path: "items", only: :update do
      resources :files, only: :show
    end
  end

  # Public upload page for clients, reached through the request's private link. No account needed.
  get "u/:token" => "uploads#show", as: :upload
  post "u/:token/items/:checklist_item_id" => "uploads#create", as: :upload_item

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#show"
end
