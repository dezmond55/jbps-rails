# config/deploy.rb (Reference only - not used for Heroku Git deployment)
# lock "~> 3.19.2"

# set :application, "jbps-rails"
# set :repo_url, "https://github.com/dezmond55/jbps-rails.git"
# set :branch, "main"
# set :deploy_to, "/home/jbpscoma/public_html/nodeapp" # Webcentral-specific, ignored by Heroku
# set :pty, true
# set :linked_files, %w["config/database.yml" "config/master.key"]
# set :linked_dirs, %w["log" "tmp/pids" "tmp/cache" "tmp/sockets" "vendor/bundle" "public/system"]

# # Default values (ignored by Heroku)
# set :format, :airbrussh
# set :log_level, :debug
# set :keep_releases, 5

# # Bundler settings (overridden by Heroku build process)
# set :bundle_path, -> { shared_path.join("vendor/bundle") }
# set :bundle_flags, "--local --path #{shared_path}/vendor/bundle" # Local gems, ignored by Heroku
# set :bundle_without, %w[development test]
# set :bundle_binstubs, nil
# set :bundle_install, false

# # Web Central SSH details (ignored by Heroku)
# set :user, "jbpscoma"
# set :ssh_options, {
#   forward_agent: false,
#   auth_methods: %w[publickey],
#   keys: "C:/Users/borbu/.ssh/id_rsa",
#   port: 22,
#   timeout: 30
# }

# # Custom asset task (not needed for Heroku, which precompiles assets)
# namespace :deploy do
#   desc "Copy precompiled assets to shared directory"
#   task :copy_assets do
#     on roles(:app) do
#       release_path = fetch(:release_path)
#       unless release_path
#         puts "Error: release_path is nil. Aborting asset copy."
#         next
#       end
#       asset_source = File.join(release_path, "public/assets")
#       puts "Checking asset source: #{asset_source}"
#       execute :ls, "-la", asset_source
#       begin
#         execute :chmod, "-R", "u+w", shared_path.join("public/assets")
#         execute :rm, "-rf", shared_path.join("public/assets/*")
#       rescue SSHKit::Command::Failed => e
#         puts "Warning: Cleanup failed due to permissions: #{e.message}. Proceeding with copy."
#       end
#       execute :mkdir, "-p", shared_path.join("public/assets")
#       if test("[ -d #{asset_source} ]")
#         within release_path do
#           execute :rsync, "-av", "--exclude='*/assets'", "--exclude='assets'", "#{asset_source}/", shared_path.join("public/assets")
#           puts "Copied assets from #{asset_source} to #{shared_path.join('public/assets')}"
#         end
#       else
#         puts "Warning: Source directory #{asset_source} does not exist in release. Skipping asset copy."
#       end
#       puts "Asset copy from release completed. Check for errors or skipped files in the log."
#     end
#   end

#   # Run copy_assets before symlinking (ignored by Heroku)
#   before "deploy:symlink:linked_dirs", "deploy:copy_assets"
# end
