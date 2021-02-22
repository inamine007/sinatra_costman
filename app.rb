require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/formkeeper'
require 'sinatra/partial'
require 'pry'
require 'bcrypt'
require 'pg'
require './helpers/helpers.rb'


configure do
  enable :sessions
  enable :partial_underscores
  set :partial_template_engine, :erb
  helpers Escape
  form_messages File.expand_path(File.join(File.dirname(__FILE__), 'messages.yaml'))
end


client = PG::connect(
  :host => ENV.fetch("HOST", "localhost"),
  :user => ENV.fetch("USER"),
  :password => ENV.fetch("PASSWORD"),
  :dbname => ENV.fetch("DBNAME")
)

before do
  unless request.path == '/' || request.path == '/signin' || request.path == '/signup' || session[:user]
    redirect '/signin'
  end
  @name = session[:user]['name'] if session[:user]
  @s_unit = [
    {'key': 'Kg', 'value': '0'}, 
    {'key': 'g', 'value': '1'}, 
    {'key': 'L', 'value': '2'}, 
    {'key': 'ml', 'value': '3'}, 
    {'key': '個', 'value': '4'}, 
    {'key': '本', 'value': '5'}, 
    {'key': '袋', 'value': '6'}
  ]
  @s_budomari = ['1', '0.9', '0.8', '0.7', '0.6', '0.5', '0.4', '0.3', '0.2', '0.1']
  @s_converted_number = ['1', '0.1', '0.01', '0.001']
end

get '/signup' do
  csrf_token_generate
  return erb :signup
end

post '/signup' do
  return redirect '/signup' unless params[:csrf_token] == session[:csrf_token]
  form do
    field :name, :present => true, :length => 1..25
    field :email, :present => true, :email => true, :length => 1..35
    field :password, :present => true, :length => 4..8
  end
  if form.failed?
    output = erb :signup
    fill_in_form(output)
  else
    name = params[:name]
    email = params[:email]
    password_salt = BCrypt::Engine.generate_salt
    password_hash = BCrypt::Engine.hash_secret(params[:password], password_salt)  
    client.exec_params("INSERT INTO users (name, email, password_salt, password_hash) VALUES ($1, $2, $3, $4)", [name, email, password_salt, password_hash])
    user = client.exec_params("SELECT * from users WHERE email = $1 AND password_hash = $2", [email, BCrypt::Engine.hash_secret(params[:password], password_salt)]).to_a.first
    session[:user] = user
    return redirect '/ingredients'
  end
end

get "/signin" do
  csrf_token_generate
  return erb :signin
end

post "/signin" do
  return redirect '/signin' unless params[:csrf_token] == session[:csrf_token]
  form do
    field :email, :present => true, :email => true, :length => 1..35
    field :password, :present => true, :length => 4..8
  end
  if form.failed?
    output = erb :signin
    fill_in_form(output)
  else
    email = params[:email]
    password = params[:password]
    tmpUser = client.exec_params("SELECT * FROM users WHERE email = $1", [email]).to_a.first
    user = client.exec_params("SELECT * FROM users WHERE password_hash = $1", [BCrypt::Engine.hash_secret(password, tmpUser['password_salt'])]).to_a.first if tmpUser
    if user.nil?
      return erb :signin
    else
      session[:user] = user
      return redirect '/ingredients'
    end
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

get '/ingredients' do
  id = session[:user]['id']  
  @ingredients = client.exec_params("SELECT * FROM ingredients WHERE user_id = #{id} ORDER BY name").to_a
  return erb :ingredients
end

get '/ingredients/new' do
  csrf_token_generate
  return erb :ingredient_new
end

get '/ingredients/:id' do
  ingredient_id = params[:id]
  @ingredient = client.exec_params("SELECT * FROM ingredients WHERE id = #{ingredient_id}").to_a.first
  return erb :ingredient
end

post "/ingredients/create" do
  return redirect '/ingredient_new' unless params[:csrf_token] == session[:csrf_token]
  form do
    field :name, :present => true, :length => 1..50
    field :trader, :present => true, :length => 1..50
    field :cost, :present => true    
  end
  if form.failed?
    output = erb :ingredient_new
    fill_in_form(output)
  else
    name = params[:name]
    trader = params[:trader]
    unit = params[:unit]
    cost = params[:cost]
    budomari = params[:budomari]
    unit_used = params[:unit_used]
    converted_number = params[:converted_number]
    cost_used = converted_number.to_i * cost.to_i / budomari.to_i
    user_id = session[:user]['id']  
    client.exec_params(
      "INSERT INTO ingredients (name, trader, unit, cost, budomari, unit_used, converted_number, cost_used, user_id)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)",
      [name, trader, unit, cost, budomari, unit_used, converted_number, cost_used, user_id]
    )
    
    return redirect '/ingredients'
  end
end

get '/ingredients/:id/edit' do
  csrf_token_generate
  ingredient_id = params[:id]
  @ingredient = client.exec_params("SELECT * FROM ingredients WHERE id = #{ingredient_id}").to_a.first  
  return erb :ingredient_edit
end

put "/ingredients/:id/update" do
  return redirect '/ingredient_new' unless params[:csrf_token] == session[:csrf_token]
  form do
    field :name, :present => true, :length => 1..50
    field :trader, :present => true, :length => 1..50
    field :cost, :present => true    
  end
  if form.failed?
    output = erb :ingredient_edit
    fill_in_form(output)
  else
    ingredient_id = params[:id]
    name = params[:name]
    trader = params[:trader]
    unit = params[:unit]
    cost = params[:cost]
    budomari = params[:budomari]
    unit_used = params[:unit_used]
    converted_number = params[:converted_number]  
    cost_used = converted_number.to_i * cost.to_i / budomari.to_i
    client.exec_params(
      "UPDATE ingredients
      SET name = $1, trader = $2, unit = $3, cost = $4, budomari = $5, unit_used = $6, converted_number = $7, cost_used = $8
      WHERE id = #{ingredient_id}",
      [name, trader, unit, cost, budomari, unit_used, converted_number, cost_used]
    )

    return redirect "/ingredients/#{ingredient_id}"
  end
end

