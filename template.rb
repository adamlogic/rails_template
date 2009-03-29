# Delete unnecessary files
  run "rm README"
  run "rm public/index.html"
  run "rm public/favicon.ico"
  run "rm public/robots.txt"
  run "rm -f public/javascripts/*"

# Copy database.yml for distribution
  run "cp config/database.yml config/database.example.yml"
  
# Set up .gitignore files
  run "touch tmp/.gitignore log/.gitignore vendor/.gitignore"
  file '.gitignore', <<-CODE
.DS_Store
log/*.log
tmp/**/*
config/database.yml
db/*.sqlite3
coverage
public/system/**/*
public/stylesheets/all.css
public/javascripts/all.js
  CODE

# Set up git repository
  git :init
  git :add => '.'
  git :commit => "-m 'Initial commit'"

# Bootstrap
  # run 'gem install adamlogic-rails_bootstrap'
  # generate 'bootstrap'
  # git :add => '.', :commit => "-m 'generated bootstrap files'"

# Use HAML
  gem 'haml'
  rake 'gems:install', :sudo => true
  rake 'gems:unpack gems:build'
  run 'haml --rails .'

# Download jQuery
  run "curl -L http://jqueryjs.googlecode.com/files/jquery-1.3.2.js > public/javascripts/jquery.js"

# Track the latest stable Rails branch
  run 'braid add git://github.com/rails/rails.git vendor/rails --branch 2-3-stable' 

# jQuery plugins and other JS/CSS widgets
  run 'mkdir public/vendor'
  git :add => '.'
  git :commit => "-m 'prepare for third-party JS/CSS plugins'"
  run 'braid add git://github.com/malsup/form.git public/vendor/jquery-form'
  run 'braid add git://github.com/adamlogic/jquery-always.git public/vendor/jquery-always'
  run 'braid add git://github.com/adamlogic/jquery-jaxy.git public/vendor/jquery-jaxy'
  run 'braid add git://github.com/adamlogic/jquery-odds_and_ends.git public/vendor/jquery-odds_and_ends'
  run 'braid add git://github.com/nathansmith/960-grid-system.git public/vendor/960-grid-system'

# Gems
  gem 'faker'
  gem 'mislav-will_paginate', :lib => 'will_paginate',  :source => 'http://gems.github.com'
  gem 'rubyist-aasm', :lib => 'aasm', :source => 'http://gems.github.com'
  gem 'thoughtbot-paperclip', :lib => 'paperclip', :source => 'http://gems.github.com'
  gem 'thoughtbot-shoulda', :lib => 'shoulda', :source => 'http://gems.github.com'
  gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source => 'http://gems.github.com'
  gem 'webrat'
  # gem 'prawn'
  # gem 'prawn-layout', :lib => 'prawn/layout'
  # gem 'fastercsv'
  # gem 'httparty'
  # gem 'RedCloth', :lib => 'redcloth'
  rake 'gems:install', :sudo => true
  rake 'gems:unpack gems:build'
  git :add => '.'
  git :commit => "-m 'adding gems'"

# Rails plugins
  run 'braid add -p git://github.com/gumayunov/custom-err-msg.git'
  run 'braid add -p git://github.com/railsgarden/message_block.git'
  run 'braid add -p git://github.com/adamlogic/message_block_extensions.git'
  run 'braid add -p git://github.com/jnunemaker/user_stamp.git'
  # run 'braid add -p git://github.com/pjhyett/auto_migrations.git'

# Cucumber
  gem 'cucumber'
  rake 'gems:install', :sudo => true
  rake 'gems:unpack gems:build'
  git :add => '.'
  git :commit => "-m 'adding cucumber'"

# Authentication
  gem 'thoughtbot-clearance', :lib => 'clearance', :source => 'http://gems.github.com'
  rake 'gems:install', :sudo => true
  rake 'gems:unpack gems:build'
  generate 'clearance'
  generate 'clearance_features'

# Open id (cargo-culted, haven't tried it yet)
  # gem 'ruby-openid', :lib => 'openid', :version => '>=2.1.2'
  # rake 'gems:install', :sudo => true
  # rake 'gems:unpack gems:build'
  # git :add => '.'
  # git :commit => "-m 'adding open id gem'"
  # run 'braid add -p git://github.com/rails/open_id_authentication.git'
  # rake 'open_id_authentication:db:create'
  # rake 'db:migrate'
  # git :add => '.'
  # git :commit => "-m 'adding open id support'"
