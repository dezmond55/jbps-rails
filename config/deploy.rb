# config valid only for current version of Capistrano
lock "~> 3.19.2"

set :application, "jbps-rails"
set :repo_url, "https://github.com/dezmond55/jbps-rails.git"
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

# Bundler settings to use pre-built gems and disable remote execution
set :bundle_path, -> { shared_path.join("vendor/bundle") }
set :bundle_flags, "--local --path #{shared_path}/vendor/bundle" # Use pre-built gems, no server-side bundle required
set :bundle_without, %w[development test] # Exclude dev/test gems
set :bundle_binstubs, nil # Disable binstub generation
set :bundle_install, false # Explicitly disable remote bundle install

# Web Central SSH details
set :user, "jbpscoma"
set :ssh_options, {
  forward_agent: false,
  auth_methods: %w[publickey],
  keys: "C:/Users/borbu/.ssh/id_rsa",
  port: 22,
  timeout: 30 # Increase timeout to handle potential delays
}

# Custom task to copy public/assets to shared directory
namespace :deploy do
  desc "Copy precompiled assets to shared directory"
  task :copy_assets do
    on roles(:app) do
      release_path = fetch(:release_path)
      unless release_path
        puts "Error: release_path is nil. Aborting asset copy."
        next
      end
      asset_source = File.join(release_path, "public/assets")
      puts "Checking asset source: #{asset_source}"
      execute :mkdir, "-p", shared_path.join("public/assets")
      if test("[ -d #{asset_source} ]")
        within release_path do
          # Copy contents of public/assets directly, avoiding nesting
          execute :cp, "-r", "public/assets/*", shared_path.join("public/assets")
          puts "Copied assets from #{asset_source} to #{shared_path.join('public/assets')}"
        end
      else
        puts "Warning: Source directory #{asset_source} does not exist in release. Skipping asset copy."
      end
      puts "Asset copy from release completed. Check for errors or skipped files in the log."
    end
  end

  # Run copy_assets before symlinking
  before "deploy:symlink:linked_dirs", "deploy:copy_assets"
end

# Custom task to copy public/assets to shared directory
namespace :deploy do
  desc "Copy precompiled assets to shared directory"
  task :copy_assets do
    on roles(:app) do
      release_path = fetch(:release_path)
      unless release_path
        puts "Error: release_path is nil. Aborting asset copy."
        next
      end
      asset_source = File.join(release_path, "public/assets")
      puts "Checking asset source: #{asset_source}"
      execute :mkdir, "-p", shared_path.join("public/assets")
      if test("[ -d #{asset_source} ]")
        within release_path do
          # Copy contents of public/assets directly, avoiding nesting
          execute :cp, "-r", "public/assets/*", shared_path.join("public/assets")
          puts "Copied assets from #{asset_source} to #{shared_path.join('public/assets')}"
        end
      else
        puts "Warning: Source directory #{asset_source} does not exist in release. Skipping asset copy."
      end
      puts "Asset copy from release completed. Check for errors or skipped files in the log."
    end
  end

  # Run copy_assets before symlinking
  before "deploy:symlink:linked_dirs", "deploy:copy_assets"
end
