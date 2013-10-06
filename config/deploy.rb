set :application, 'codigo-banana'
set :repository, 'jekyll/_site'
set :scm, :none
set :deploy_via, :copy
set :copy_compression, :gzip
set :use_sudo, false
set :host, 'szot.platan.us'
set :ssh_options, { :forward_agent => true }

role :web, host
role :app, host

set :user, 'deploy'


set :deploy_to,    "/home/#{user}/applications/#{application}"

before 'deploy:update', 'deploy:update_jekyll'

namespace :deploy do

  [:start, :stop, :restart, :finalize_update].each do |t|
    desc "#{t} task is a no-op with jekyll"
    task t, :roles => :app do ; end
  end

  desc 'Run jekyll to update site before uploading'
  task :update_jekyll do
    %x(rm -rf jekyll/_site/* && cd jekyll && jekyll build)
  end

end