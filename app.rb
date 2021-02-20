require 'sinatra'
require 'sinatra/reloader'
require 'pry'
require 'rack/csrf'
require './helpers/helpers.rb'
require 'pg'

configure do
  enable :sessions
	use Rack::Session::Cookie
	use Rack::Csrf, :raise => true
  helpers Escape  
end


client = PG::connect(
  :host => ENV.fetch("HOST", "localhost"),
  :user => ENV.fetch("USER"),
  :password => ENV.fetch("PASSWORD"),
  :dbname => ENV.fetch("DBNAME")
)

get '/' do
  @user = client.exec_params("SELECT * FROM test").to_a.first
  erb :index
end

post '/test' do  
  @name = "#{h(params[:name])}"
  erb :index
end