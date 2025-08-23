# Server configuration for production environment
server "192.250.232.174", user: fetch(:user), roles: %w[app db web]
set :rails_env, "production"
