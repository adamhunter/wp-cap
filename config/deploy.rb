set :application, "NAME_OF_APP"
set :domain, "DOMAIN_APP_AND_REPO_ARE_ON"
set :user, "USERNAME"
set :port, "PORT_IF_NOT_22"
set :use_sudo, false
set :scm, :git
set :deploy_via, :remote_cache

set :repository,  "ssh://#{user}@#{domain}:#{port}/var/repos/#{application}.git"

set :deploy_to, "/absolute/path/to/app/#{application}"

role :app, domain
role :web, domain
role :db,  domain, :primary => true

namespace :deploy do
  [:start, :stop, :finalize_update, :restart].each do |t|
    desc "#{t} task is a no-op with just apache"
    task t, :roles => :app do ; end
  end
  
  desc "Setup deploy"
  task :setup, :roles => :app do
    run "mkdir -p #{deploy_to} #{deploy_to}/releases #{deploy_to}/shared && chmod g+w #{deploy_to} #{deploy_to}/releases #{deploy_to}/shared"
  end
end


require 'erb' 
require 'open-uri'
before "deploy:setup", :db 
after "deploy:update_code", "db:symlink" 

set :db_name, 'NAME'
set :db_user, 'USER'
set :db_pass, 'PASS'
set :db_host, 'localhost'
set :db_prfx, 'wp_'
# https doesn't seem to work :(
set :secret_keys, open('http://api.wordpress.org/secret-key/1.1/').read

namespace :db do 
  desc "Create wp-config.php in shared path" 
  task :default do 
    db_config = ERB.new <<-EOF 
    
    <?php
    define('DB_NAME', '#{db_name}');
    define('DB_USER', '#{db_user}');
    define('DB_PASSWORD', '#{db_pass}');
    define('DB_HOST', '#{db_host}');
    define('DB_CHARSET', 'utf8');
    define('DB_COLLATE', '');
    #{secret_keys}
    $table_prefix  = '#{db_prfx}';
    define ('WPLANG', '');
    if ( !defined('ABSPATH') )
    	define('ABSPATH', dirname(__FILE__) . '/');
    require_once(ABSPATH . 'wp-settings.php');
    EOF

    run "mkdir -p #{shared_path}/config" 
    put db_config.result, "#{shared_path}/config/wp-config.php" 
  end 

  desc "Make symlink for wp-config.php" 
  task :symlink do 
    run "ln -nfs #{shared_path}/config/wp-config.php #{release_path}/wp-config.php" 
  end 
end
