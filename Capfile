# Load DSL and set up stages
require "capistrano/setup"

# Include default deployment tasks
require "capistrano/deploy"

# Load the SCM plugin appropriate to your project:
#
# require "capistrano/scm/hg"
# install_plugin Capistrano::SCM::Hg
# or
# require "capistrano/scm/svn"
# install_plugin Capistrano::SCM::Svn
# or
require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

# Include tasks from other gems included in your Gemfile
require "capistrano/rails"
# Explicitly disable capistrano-bundler to avoid bundle command
# require "capistrano/bundler"

# Clear any existing Bundler tasks to ensure our no-op definitions take precedence
Rake::Task["bundler:install"].clear if Rake::Task.task_defined?("bundler:install")
Rake::Task["bundler:config"].clear if Rake::Task.task_defined?("bundler:config")

# Disable Bundler tasks with custom no-op definitions
namespace :bundler do
  task :install do
    # No-op to override default install task
    puts "Skipping bundler:install as gems are pre-built in vendor/bundle"
  end
  task :config do
    # No-op to override default config task
    puts "Skipping bundler:config as gems are pre-built in vendor/bundle"
  end
end

# For documentation on these, see for example:
#
#   https://github.com/capistrano/rvm
#   https://github.com/capistrano/rbenv
#   https://github.com/capistrano/chruby
#   https://github.com/capistrano/bundler
#   https://github.com/capistrano/rails
#   https://github.com/capistrano/passenger
#
# require "capistrano/rvm"
# require "capistrano/rbenv"
# require "capistrano/chruby"
# require "capistrano/bundler"
# require "capistrano/rails/assets"
# require "capistrano/rails/migrations"
# require "capistrano/passenger"

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }