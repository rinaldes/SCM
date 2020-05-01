# config valid only for current version of Capistrano
# lock '3.6.1'
SSHKit.config.command_map[:rake] = "bundle exec rake"

set :application, 'hanamart'
set :repo_url, 'git@gitlab.com:wina21/scm.git'

# Default branch is :master
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/home/ministop/deploy/hanamart'
# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true
set :linked_files, %w{config/database.yml}
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}
# Default value for :linked_files is []
# append :linked_files, 'config/database.yml', 'config/secrets.yml'

# Default value for linked_dirs is []
# append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system'

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 100

# Symlinks
# after  'deploy', 'symlinks:uploads'
# namespace :symlinks do
#   desc "Create sysmlinks for public/uploads directory"
#   task :uploads do
#     uploads = "#{shared_path}/public/uploads"
#     run "rm -rf #{release_path}/public/uploads"
#     run "ln -nsf #{uploads} #{release_path}/public/uploads"
#   end
# end