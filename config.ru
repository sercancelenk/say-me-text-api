require 'sinatra'
require './sayme'

# set :run, false
set :environment, :development
# set :lock, false

run SayMeApp.new