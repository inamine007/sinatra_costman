require 'sinatra'
require 'sinatra/reloader'
require 'pry'
require 'bcrypt'
require 'pg'
require './helpers/helpers.rb'

configure do
  enable :sessions
  helpers Escape  
end


client = PG::connect(
  :host => ENV.fetch("HOST", "localhost"),
  :user => ENV.fetch("USER"),
  :password => ENV.fetch("PASSWORD"),
  :dbname => ENV.fetch("DBNAME")
)


get '/signup' do
  csrf_token_generate
  return erb :signup
end

post '/signup' do
  return redirect '/signin' unless params[:csrf_token] == session[:csrf_token]  
  name = params[:name]
  email = params[:email]
  password_salt = BCrypt::Engine.generate_salt
  password_hash = BCrypt::Engine.hash_secret(params[:password], password_salt)  
  client.exec_params("INSERT INTO users (name, email, password_salt, password_hash) VALUES ($1, $2, $3, $4)", [name, email, password_salt, password_hash])
  user = client.exec_params("SELECT * from users WHERE email = $1 AND password_hash = $2", [email, BCrypt::Engine.hash_secret(params[:password], password_salt)]).to_a.first
  session[:user] = user
  return redirect '/mypage'
end

get "/mypage" do
  @name = session[:user]['name']
  return erb :mypage
end

get "/signin" do
  csrf_token_generate
  return erb :signin
end

post "/signin" do
  return redirect '/signin' unless params[:csrf_token] == session[:csrf_token]
  email = params[:email]
  password = params[:password]
  tmpUser = client.exec_params("SELECT * FROM users WHERE email = $1", [email]).to_a.first
  user = client.exec_params("SELECT * FROM users WHERE password_hash = $1", [BCrypt::Engine.hash_secret(password, tmpUser['password_salt'])]).to_a.first  
  if user.nil?
    return erb :signin
  else
    session[:user] = user
    return redirect '/mypage'
  end
end

delete "/signout" do
  session[:user] = nil
  return redirect '/signin'
end

delete "/user" do
  user = session[:user]
  client.exec_params("DELETE FROM users WHERE email = $1 AND password_hash = $2", [user['email'], user['password_hash']]).to_a.first
  session[:user] = nil
  return redirect '/signin'
end
