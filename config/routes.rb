Rails.application.routes.draw do
  root "pages#home"
  get "about", to: "pages#about"

  # Hide Services on live site until ready
  get "/services", to: redirect("/"), unless: -> { Rails.env.development? }
  get "/services/*path", to: redirect("/"), unless: -> { Rails.env.development? }

  resources :services
end
