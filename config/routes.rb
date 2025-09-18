Rails.application.routes.draw do
  resources :services
  root "pages#home"
  get "up" => "rails/health#show", as: :rails_health_check
  get "/about" => "pages#about"
  get "/nodeapp", to: redirect("/")
  # Optional PWA routes
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  # Remove or comment out
  # get "pages/home"
end
