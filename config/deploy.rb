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
      execute :mkdir, "-p", shared_path.join("public/assets")
      assets = Dir.glob("public/assets/**/*").select { |f| File.file?(f) }
      batch_size = 10 # Process files in batches to avoid overwhelming the connection
      assets.each_slice(batch_size) do |batch|
        begin
          batch.each do |file|
            relative_path = file.sub(/^public\/assets\//, "")
            upload! file, shared_path.join("public/assets/#{relative_path}")
          end
        rescue SSHKit::Runner::ExecuteError, Errno::ECONNRESET => e
          puts "Error during upload: #{e.message}. Retrying batch..."
          retry # Retry the current batch on connection error
        end
      end
    end
  end

  # Run copy_assets before symlinking
  before "deploy:symlink:linked_dirs", "deploy:copy_assets"
end
