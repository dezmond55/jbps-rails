Rails.application.routes.draw do
  root 'pages#home' # Sets the root path to the home action of the Pages controller
  get "up" => "rails/health#show", as: :rails_health_check # Keep health check

  # Optional PWA routes (uncomment if needed later)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Remove or comment out the generated get "pages/home" if root is used
  # get "pages/home"
end