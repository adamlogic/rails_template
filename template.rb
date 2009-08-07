# Gather some info
puts
interwebs = yes?('Are you connected to the Interwebs?')
deploy = interwebs && yes?('Want to deploy to Heroku?')
freeze = yes?('Freeze everything?')
scaffold = ask('Generate a scaffold for your first resource [ex: post title:string body:text] (leave blank to skip)')
appname = `pwd`.split('/').last.strip
domain = ask("Enter production domain if other than #{appname}.com:")
domain = "#{appname}.com" if domain.blank?
if gmail = yes?('Use Gmail to send mail?')
  gmail_address = ask('Full gmail address:')
  gmail_password = ask('Password:')
end

# Delete unneeded files
run 'rm README'
run 'rm public/index.html'
run 'rm public/favicon.ico'
run 'rm public/robots.txt'
run 'rm -f public/javascripts/*'

# Prepare .gitignore files
run 'touch tmp/.gitignore log/.gitignore vendor/.gitignore'
file '.gitignore', <<-CODE.gsub(/^\s*/,'')
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
if freeze
  rake 'rails:freeze:gems'
  git :add => '.', :commit => "-m 'freeze current rails version'"
end

# Download jQuery
if interwebs
  run 'curl -L http://ajax.googleapis.com/ajax/libs/jquery/1/jquery.js > public/javascripts/jquery.js'
else
  run 'cp ~/projects/rails_template/files/jquery.js public/javascripts/jquery.js'
end
git :add => '.', :commit => "-m 'add jquery'"

# Gems
gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source  => "http://gems.github.com"
gem 'thoughtbot-paperclip', :lib => 'paperclip', :source => 'http://gems.github.com'
gem 'ambethia-smtp-tls', :lib => 'smtp-tls', :source => 'http://gems.github.com/'
rake 'gems:unpack gems:build' if freeze
git :add => '.', :commit => "-m 'add gems'"

# Cucumber
generate :cucumber, '--testunit'
rake 'gems:unpack gems:build' if freeze
git :add => '.', :commit => "-m 'add cucumber'"

# Authentication
gem 'thoughtbot-clearance', :lib => 'clearance', :source => 'http://gems.github.com'
rake 'gems:unpack' if freeze
generate :clearance
generate :clearance_features, '-f'
rake 'db:migrate'
git :add => '.', :commit => "-m 'add clearance'"

# Scaffold first resource (assume authentication is required)
if scaffold.present?
  generate 'nifty_scaffold', scaffold
  resource_name = scaffold.split(' ').first.downcase.pluralize
  gsub_file "app/controllers/#{resource_name}_controller.rb", /.*ApplicationController.*/, "\\0\n  before_filter :authenticate\n"
  root_route = ":controller => '#{resource_name}', :action => 'index'"
  rake 'db:migrate'
  git :add => '.', :commit => "-m 'generated scaffold for #{resource_name}'"
end

# Remove the default routes and add root to make clearance happy
root_route ||= ":controller => 'clearance/sessions', :action => 'new'"
gsub_file 'config/routes.rb', /end\s*\Z/m, "\n  map.root #{root_route}\n\\0"
git :add => '.', :commit => "-m 'set up a new root route'"

# Add global constants for clearance
append_file 'config/environments/development.rb', "\nHOST = 'localhost:3000'"
append_file 'config/environments/test.rb', "\nHOST = 'localhost:3000'"
append_file 'config/environments/cucumber.rb', "\nHOST = 'localhost:3000'"
append_file 'config/environments/production.rb', "\nHOST = '#{domain}'"
gsub_file 'config/environment.rb', /RAILS_GEM_VERSION.*/, "\\0\n\nDO_NOT_REPLY = 'donotreply@#{domain}'"
git :add => '.', :commit => "-m 'add constants for clearance'"

# Set up gmail for sending mail
if gmail
  environment <<-CODE.gsub(/^\s*/,''), :env => 'production'
    config.action_mailer.smtp_settings = {
      :address        => "smtp.gmail.com",
      :port           => 587,
      :domain         => "#{gmail_address}",
      :authentication => :plain,
      :user_name      => "#{gmail_address}",
      :password       => "#{gmail_password}" 
    }
  CODE
end

# Start with a reasonable layout to work with
generate :nifty_layout
git :add => '.', :commit => "-m 'add nifty_layout'"

# Set up and deploy on Heroku
if deploy
  file '.gems', <<-CODE.gsub(/^\s*/,'') unless freeze
    rails --version 2.3.3
    thoughtbot-paperclip --source gems.github.com
    thoughtbot-clearance --source gems.github.com
    thoughtbot-factory_girl --source gems.github.com
    ambethia-smtp-tls --source gems.github.com
  CODE
  git :add => '.', :commit => "-m 'add .gems manifest for heroku'"
  run 'heroku create'
  run "heroku rename #{appname}"
  git :push => 'heroku master'
  run 'heroku rake db:migrate'
  run 'heroku open'
end
