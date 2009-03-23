# delete unnecessary files
  run "rm README"
  run "rm public/index.html"
  run "rm public/favicon.ico"
  run "rm public/robots.txt"
  run "rm -f public/javascripts/*"

# use HAML
  gem 'haml'
  rake 'gems:install', :sudo => true
  rake 'gems:unpack gems:build'
  run 'haml --rails .'

# download jQuery
  run "curl -L http://jqueryjs.googlecode.com/files/jquery-1.3.2.js > public/javascripts/jquery.js"

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

# track the latest stable Rails branch
  run 'braid add git://github.com/rails/rails.git vendor/rails --branch 2-3-stable' 

# jQuery plugins
  run 'mkdir public/vendor'
  git :add => '.'
  git :commit => "-am 'prepare for third-party JS/CSS plugins'"
  run 'braid add git://github.com/malsup/form.git public/vendor/jquery-form'
  run 'braid add git://github.com/adamlogic/jquery-always.git public/vendor/jquery-always'
  run 'braid add git://github.com/adamlogic/jquery-jaxy.git public/vendor/jquery-jaxy'

# gems
  # gem 'RedCloth', :lib => 'redcloth'
  gem 'faker'
  gem 'mislav-will_paginate', :lib => 'will_paginate',  :source => 'http://gems.github.com'
  gem 'thoughtbot-paperclip', :lib => 'paperclip', :source => 'http://gems.github.com'
  gem 'thoughtbot-shoulda', :lib => 'shoulda', :source => 'http://gems.github.com'
  gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source => 'http://gems.github.com'
  rake 'gems:install', :sudo => true
  rake 'gems:unpack gems:build'
  git :add => '.'
  git :commit => "-am 'adding gems'"

# rails plugins
  run 'braid add -p git://github.com/rubyist/aasm.git'
  run 'braid add -p git://github.com/pjhyett/auto_migrations.git'
  run 'braid add -p git://github.com/gumayunov/custom-err-msg.git'
  run 'braid add -p git://github.com/railsgarden/message_block.git'

# cucumber
  gem 'cucumber'
  rake 'gems:install', :sudo => true
  rake 'gems:unpack gems:build'
  git :add => '.'
  git :commit => "-am 'adding cucumber'"

# authentication
  gem 'thoughtbot-clearance', :lib => 'clearance', :source => 'http://gems.github.com'
  rake 'gems:install', :sudo => true
  rake 'gems:unpack gems:build'
  generate 'clearance'
  generate 'clearance_features'

# open id
  # gem 'ruby-openid', :lib => 'openid', :version => '>=2.1.2'
  # rake 'gems:install', :sudo => true
  # rake 'gems:unpack gems:build'
  # git :add => '.'
  # git :commit => "-am 'adding open id gem'"
  # run 'braid add -p git://github.com/rails/open_id_authentication.git'
  # rake 'open_id_authentication:db:create'
  # rake 'db:migrate'
  # git :add => '.'
  # git :commit => "-am 'adding open id support'"
