# Helper methods

def append(filename, content)
  existing_content = File.read(filename)
  new_content = existing_content + "\n" + content
  file filename, new_content
end


# Gather some info
puts
interwebs = yes?('Are you connected to the Interwebs?')
deploy = yes?('Want to deploy to Heroku?')
appname = `pwd`.split('/').last

# Delete unneeded files
run 'rm README'
run 'rm public/index.html'
run 'rm public/favicon.ico'
run 'rm public/robots.txt'
run 'rm -f public/javascripts/*'

# Prepare .gitignore files
run 'touch tmp/.gitignore log/.gitignore vendor/.gitignore'
file '.gitignore', <<-CODE
.DS_Store
log/*.log
tmp/*
tmp/**/*
db/*.sqlite3
coverage
public/system/**/*
public/stylesheets/all.css
public/javascripts/all.js
CODE

# Set up git repository
git :init
git :add => '.', :commit => "-m 'first!'"

# Freeze Rails
rake 'rails:freeze:gems'
git :add => '.', :commit => "-m 'freeze current rails version'"

# Download jQuery
if interwebs
  run 'curl -L http://ajax.googleapis.com/ajax/libs/jquery/1/jquery.js > public/javascripts/jquery.js'
else
  run 'cp ~/projects/rails_template/files/jquery.js public/javascripts/jquery.js'
end
git :add => '.', :commit => "-m 'add jquery'"

# Gems
gem 'webrat'
gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source  => "http://gems.github.com"
gem 'thoughtbot-paperclip', :lib => 'paperclip', :source => 'http://gems.github.com'
rake 'gems:unpack gems:build'
git :add => '.', :commit => "-m 'add gems'"

# Cucumber
gem 'cucumber'
generate :cucumber
rake 'gems:unpack gems:build'
git :add => '.', :commit => "-m 'add cucumber'"

# Authentication
gem 'thoughtbot-clearance', :lib => 'clearance', :source => 'http://gems.github.com'
rake 'gems:unpack'
generate :clearance
generate :clearance_features, '-f'
rake 'db:migrate'
git :add => '.', :commit => "-m 'add clearance'"

# Remove the default routes and add root to make clearance happy
file 'config/routes.rb', <<-CODE
ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'clearance/sessions', :action => 'new'
end
CODE
git :add => '.', :commit => "-m 'set up a new root route'"

# Add global constants for clearance
append 'config/environment.rb', "\nDO_NOT_REPLY = 'donotreply@#{appname}.com'"
append 'config/environments/development.rb', "\nHOST = 'localhost:3000'"
append 'config/environments/test.rb', "\nHOST = 'localhost:3000'"
append 'config/environments/cucumber.rb', "\nHOST = 'localhost:3000'"
append 'config/environments/production.rb', "\nHOST = '#{appname}.com'"
git :add => '.', :commit => "-m 'add constants for clearance'"

# Start with a reasonable layout to work with
generate :nifty_layout
git :add => '.', :commit => "-m 'add nifty_layout'"

# Set up and deploy on Heroku
if deploy
  run "heroku create"
  run "heroku rename #{appname}"
  git :push => 'heroku master'
  run 'heroku db:migrate'
  run 'heroku open'
end
