Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  root "pages#home"
  get "about", to: "pages#about"

  # Hide Services on live site until ready
  get "/services", to: redirect("/"), constraints: ->(req) { Rails.env.production? }
  get "/services/*path", to: redirect("/"), constraints: ->(req) { Rails.env.production? }

  resources :services
end
