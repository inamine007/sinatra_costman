require 'sinatra'
require 'sinatra/reloader'
require 'pry'
require 'rack/csrf'
require './helpers/helpers.rb'

configure do
  enable :sessions
	use Rack::Session::Cookie
	use Rack::Csrf, :raise => true
  helpers Escape  
end

get '/' do  
  erb :index
end

post '/test' do  
  @name = "#{h(params[:name])}"
  erb :index
end