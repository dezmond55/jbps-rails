# config valid only for current version of Capistrano
lock "~> 3.19.2"

set :application, "jbps-rails"
set :repo_url, "https://github.com/dezmond55/jbps-rails.git" # Replace with your Git repo URL or use a local path
set :branch, "main"
set :deploy_to, "/home/jbpscoma/public_html/nodeapp"
set :pty, true
set :linked_files, %w[config/database.yml config/master.key]
set :linked_dirs, %w[log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system]

# Default value for :format is :airbrussh
set :format, :airbrussh

# Default value for :log_level is :debug
set :log_level, :debug

# Default value for :keep_releases is 5
set :keep_releases, 5

# Web Central SSH details
set :user, "jbpscoma" # Replace with your actual cPanel username
set :password, "#!0031Jbps0031!#" # Replace with your cPanel password (or use SSH key)
set :ssh_options, {
  forward_agent: false,
  auth_methods: %w[password],
  port: 22 # Default SSH port, adjust if different
}
