Rails.application.routes.draw do
  root "pages#home" # Sets the root path to the home action
  get "up" => "rails/health#show", as: :rails_health_check # Keep health check
  get "/about" => "pages#about"
  get "/nodeapp", to: redirect("/") # Redirect legacy path to root
  # Placeholder routes
  get "/services", to: redirect("/")
  get "/contact", to: redirect("/")
  # Optional PWA routes (uncomment if needed later)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  # Remove or comment out the generated get "pages/home"
  # get "pages/home"
end
