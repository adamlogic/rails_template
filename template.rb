# delete unnecessary files
  run "rm README"
  run "rm public/index.html"
  run "rm public/favicon.ico"
  run "rm public/robots.txt"
  run "rm -f public/javascripts/*"

# use HAML
  gem 'haml', :version => '>=2.0.6'
  rake 'gems:install', :sudo => true
  run 'haml --rails .'

# download jQuery
  run "curl -L http://jqueryjs.googlecode.com/files/jquery-1.2.6.min.js > public/javascripts/jquery.js"
  run "curl -L http://jqueryjs.googlecode.com/svn/trunk/plugins/form/jquery.form.js > public/javascripts/jquery.form.js"

# set up git repository
  git :init
  git :add => '.'
  
# copy database.yml for distribution use
  run "cp config/database.yml config/database.yml.example"
  
# set up .gitignore files
  run "touch tmp/.gitignore log/.gitignore vendor/.gitignore"
  run "curl -L http://github.com/adamlogic/rails_template.git/files/.gitignore > .gitignore"

# commit all work so far to the repository
  git :add => '.'
  git :commit => "-am 'Initial commit'"

# freeze edge rails (or a branch)
  run 'braid add git://github.com/rails/rails.git vendor/rails' 
  # run 'braid add git://github.com/rails/rails.git --branch 2-2-stable' 

# jQuery plugins
  run 'mkdir public/vendor'
  git :add => '.'
  git :commit => "-am 'prepare for third-party JS/CSS plugins'"
  run 'braid add git://github.com/adamlogic/jquery-ensure.git public/vendor/jquery-ensure'
  run 'braid add git://github.com/adamlogic/jquery-jaxy.git public/vendor/jquery-jaxy'

# gems
  gem 'faker', :version => '>=0.3.1'
  gem 'mislav-will_paginate', :lib => 'will_paginate',  :source => 'http://gems.github.com', :version => '>=2.3.6'
  gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source => 'http://gems.github.com', :version => '>=1.1.5'
  gem 'RedCloth', :lib => 'redcloth', :version => '>=4.1.1'
  rake 'gems:install gems:unpack gems:build', :sudo => true
  git :add => '.'
  git :commit => "-am 'adding gems'"

# rails plugins
  run 'braid add -p git://github.com/rubyist/aasm.git'
  run 'braid add -p git://github.com/giraffesoft/resource_controller.git'
  run 'braid add -p git://github.com/sbecker/asset_packager.git'

# rspec
  run 'braid add -p git://github.com/dchelimsky/rspec.git'
  run 'braid add -p git://github.com/dchelimsky/rspec-rails.git'
  generate 'rspec'
  git :add => '.'
  git :commit => "-am 'adding rspec'"

# authentication
  gem 'authlogic', :version => '>=1.3.9'
  generate 'session user_session'

# open id
  gem 'ruby-openid', :lib => 'openid', :version => '>=2.1.2'
  rake 'gems:install gems:unpack gems:build', :sudo => true
  git :add => '.'
  git :commit => "-am 'adding open id gem'"
  run 'braid add -p git://github.com/rails/open_id_authentication.git'
  rake 'open_id_authentication:db:create'
  rake 'db:migrate'
  git :add => '.'
  git :commit => "-am 'adding open id support'"
