# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rake'
require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
  begin
    require 'rubyserial'
  rescue LoadError => e
    spec.pattern.exclude("spec/rtu_client_spec.rb", "spec/rtu_server_spec.rb")
  end
end

task :default => :spec

task :pry do
  sh "bundle exec pry -r ./lib/rmodbus.rb"
end
