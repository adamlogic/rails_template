# Lots of goodies in here were taken from http://github.com/drnic/rails-templates/blob/master/mocra.rb

# wrap template commands in block so their execution can be controlled
# in unit testing
def template(&block)
  @store_template = block
end

template do

  # Gather some info
  puts
  interwebs = yes?('Are you connected to the Interwebs?')
  deploy = interwebs && yes?('Want to deploy to Heroku?')
  freeze = yes?('Freeze everything?')
  scaffold = ask('Generate a scaffold for your first resource [ex: post title:string body:text] (leave blank to skip):')
  resource_name = scaffold.split(' ').first.downcase.pluralize if scaffold.present?
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
  run 'rm -f public/javascripts/*'
  run 'rm -rf test'

  # Prepare .gitignore files
  run 'touch tmp/.gitignore log/.gitignore vendor/.gitignore'
  file '.gitignore', <<-CODE.gsub(/^    /,'')
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
  git :add => '.'
  git :commit => "-m 'first!'"

  # Download jQuery
  if interwebs
    run 'curl -L http://ajax.googleapis.com/ajax/libs/jquery/1/jquery.js > public/javascripts/jquery.js'
  else
    run 'cp ~/projects/rails_template/files/jquery.js public/javascripts/jquery.js'
  end
  git :add => '.'
  git :commit => "-m 'add jquery'"

  # Gems
  heroku_gem 'thoughtbot-factory_girl', :source => 'http://gems.github.com', :lib => 'factory_girl'
  heroku_gem 'thoughtbot-paperclip',    :source => 'http://gems.github.com', :lib => 'paperclip'
  heroku_gem 'ambethia-smtp-tls',       :source => 'http://gems.github.com', :lib => 'smtp-tls'
  heroku_gem 'mislav-will_paginate',    :source => 'http://gems.github.com', :lib => 'will_paginate'
  rake 'gems:unpack gems:build' if freeze
  git :add => '.'
  git :commit => "-m 'add gems'"

  # HAML
  run "haml --rails ."
  git :add => '.'
  git :commit => "-m 'use haml'"

  # Freeze Rails
  if freeze
    rake 'rails:freeze:gems'
    git :add => '.'
    git :commit => "-m 'freeze current rails version'"
  end

  # Cucumber
  generate :cucumber
  rake 'gems:unpack gems:build' if freeze
  git :add => '.'
  git :commit => "-m 'add cucumber'"

  # Rspec
  gem_with_version "rspec",       :lib => false, :env => 'test'
  gem_with_version "rspec-rails", :lib => false, :env => 'test'
  gem_with_version "rspec",       :lib => false, :env => 'cucumber'
  gem_with_version "rspec-rails", :lib => false, :env => 'cucumber'
  rake 'gems:unpack' if freeze
  generate 'rspec'
  git :add => '.'
  git :commit => "-m 'add rspec'"

  # Fakeweb
  gem_with_version 'fakeweb', :env => 'test'
  gem_with_version 'fakeweb', :env => 'cucumber'
  rake 'gems:unpack' if freeze
  append_file 'features/support/env.rb', <<-CODE.gsub(/^    /,'')
    Before do
      FakeWeb.allow_net_connect = false
    end
  CODE
  git :add => '.'
  git :commit => "-m 'add fakeweb'"

  # Default rake task
  default_task = /^.*task.*default.*\n/
  gsub_file 'lib/tasks/rspec.rake', default_task, ''
  gsub_file 'lib/tasks/cucumber.rake', default_task, ''
  file 'lib/tasks/default.rake', <<-CODE.gsub(/^    /,'')
    Rake::Task[:default].prerequisites.clear

    desc "Run cucumber and rspec"
    task :default => ['spec', 'cucumber']
  CODE
  git :add => '.'
  git :commit => "-m 'add default rake task'"

  # Authentication
  heroku_gem 'thoughtbot-clearance', :lib => 'clearance', :source => 'http://gems.github.com'
  rake 'gems:unpack' if freeze
  generate :clearance
  generate :clearance_features, '-f'
  rake 'db:migrate'
  git :add => '.'
  git :commit => "-m 'add clearance'"

  # Remove the default routes and add root to make clearance happy
  root_route = resource_name ? ":controller => '#{resource_name}', :action => 'index'" : ":controller => 'clearance/sessions', :action => 'new'"
  file 'config/routes.rb', <<-CODE.gsub(/^    /,'')
    ActionController::Routing::Routes.draw do |map|
      map.root #{root_route}
    end
  CODE
  git :add => '.'
  git :commit => "-m 'set up a new root route and remove defaults'"

  # Add global constants for clearance
  append_file 'config/environments/development.rb', "\nHOST = 'localhost:3000'"
  append_file 'config/environments/test.rb', "\nHOST = 'localhost:3000'"
  append_file 'config/environments/cucumber.rb', "\nHOST = 'localhost:3000'"
  append_file 'config/environments/production.rb', "\nHOST = '#{domain}'"
  gsub_file 'config/environment.rb', /RAILS_GEM_VERSION.*/, "\\0\n\nDO_NOT_REPLY = 'donotreply@#{domain}'"
  git :add => '.'
  git :commit => "-m 'add constants for clearance'"

  # Scaffold first resource (assume authentication is required)
  if scaffold.present?
    generate 'nifty_scaffold --rspec --haml', scaffold
    gsub_file "app/controllers/#{resource_name}_controller.rb", /.*ApplicationController.*/, <<-CODE.gsub(/^    /,'')
    \\0
      before_filter :authenticate
    CODE
    run "rm -rf spec/controllers"
    rake 'db:migrate'
    git :add => '.'
    git :commit => "-m 'generated scaffold for #{resource_name}'"
  end

  # Set up gmail for sending mail
  if gmail
    environment <<-CODE.gsub(/^      /,''), :env => 'production'
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
  git :add => '.'
  git :commit => "-m 'setup gmail configuration'"

  # Provide a placeholder for S3 info
  generate :nifty_config, 'paperclip'
  file 'config/paperclip_config.yml', <<-CODE.gsub(/^    /,'')
    # USAGE: has_attached_file :photo, { :styles => { :thumb => "24x24#" }}.merge(PAPERCLIP_CONFIG)

    local: &local
      url:  '/system/:attachment/:style/:id_partition/:basename.:extension'
      path: '/:rails_root/public/system/:attachment/:style/:id_partition/:basename.:extension'

    s3: &s3
      storage: :s3
      s3_credentials: 
        access_key_id:     
        secret_access_key: 
      path:   ':attachment/:id/:style.:extension'
      bucket: 'vacationtrade.com'

    development:
      <<: *local
      #<<: *s3

    test:
      <<: *local

    production:
      <<: *s3
  CODE
  git :add => '.'
  git :commit => "-m 'add placeholder for S3 configuration'"
  

  # Start with a reasonable layout to work with
  generate :nifty_layout, '--haml'
  git :add => '.'
  git :commit => "-m 'generate nifty_layout'"

  # Set up and deploy on Heroku
  if deploy
    run 'heroku create'
    run "heroku rename #{appname}"
    git :push => 'heroku master'
    run 'heroku rake db:migrate'
    run 'heroku open'
  end

end

def heroku(cmd, arguments="")
  run "heroku #{cmd} #{arguments}"
end

def gem_with_version(name, options = {})
  if gem_spec = Gem.source_index.find_name(name).last
    version = gem_spec.version.to_s
    options = {:version => ">= #{version}"}.merge(options)
    gem(name, options)
  else
    $stderr.puts "ERROR: cannot find gem #{name}; cannot load version. Adding it anyway."
    gem(name, options)
  end
  options
end

def remove_gems(options)
  env = options.delete(:env)
  gems_code = /^\s*config.gem.*\n/
  file = env.nil? ? 'config/environment.rb' : "config/environments/#{env}.rb"
  gsub_file file, gems_code, ""
end

# Usage:
#   heroku_gem 'oauth'
#   heroku_gem 'hpricot', :version => '>= 0.2', :source => 'code.whytheluckystiff.net'
#   heroku_gem 'dm-core', :version => '0.9.10'
def heroku_gem(gem, options = {})
  options = gem_with_version(gem, options)
  file ".gems", "" unless File.exists?(".gems")

  version_str = options[:version] ? "--version '#{options[:version]}'" : ""
  source_str  = options[:source]  ? "--source '#{options[:source]}'" : ""
  append_file '.gems', "#{gem} #{version_str} #{source_str}\n"
end

def run_template
  @store_template.call
end

run_template unless ENV['TEST_MODE'] # hold off running the template whilst in unit testing mode

