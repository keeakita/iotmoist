require 'rubygems'
require 'sinatra'
require File.expand_path '../webserver.rb', __FILE__

run Sinatra::Application
