Rails.application.routes.draw do
  devise_for :users

  authenticated :user do
    root "dashboard#show", as: :authenticated_root
  end

  unauthenticated do
    devise_scope :user do
      root "devise/sessions#new", as: :unauthenticated_root
    end
  end

  get "dashboard", to: "dashboard#show"
  resources :slides, only: [:index, :show]
  resources :reviews, only: [:index, :show] do
    member { post :decide }
  end
  resources :audit_logs, only: [:index, :show], path: "audit-logs"
  get "retention", to: "retention#index", as: :retention_queue
  scope path: "settings", as: "settings" do
    get "storage", to: "settings/storage#show"
    post "storage/refresh", to: "settings/storage#refresh", as: :storage_refresh
    resources :archive_rules, path: "archive-rules", controller: "archive_rules", except: :show do
      collection { post :validate }
      member { post :duplicate }
    end
  end
  namespace :settings do
    resources :api_connections, except: :show do
      member do
        post :test
        post :sync
        patch :toggle
      end
    end
  end
  get "up" => "rails/health#show", as: :rails_health_check
end
