require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/partial'
require 'sinatra/json'
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
  # unless request.path == '/' || request.path == '/signin' || request.path == '/signup' || session[:user]
  #   redirect '/signin'
  # end
  @name = session[:user]['name'] if session[:user]  
  @s_unit= {'Kg': '0','g': '1', 'L': '2','ml': '3', '個': '4', '本': '5', '袋': '6'}
  @s_budomari = ['1', '0.9', '0.8', '0.7', '0.6', '0.5', '0.4', '0.3', '0.2', '0.1']
  @s_converted_number = ['1', '0.1', '0.01', '0.001']
end

get '/signup' do
  csrf_token_generate  
  return erb :signup
end

post '/signup' do  
  return redirect '/signup' unless params[:csrf_token] == session[:csrf_token]
  name = params[:name]
  email = params[:email]
  password_salt = BCrypt::Engine.generate_salt
  password_hash = BCrypt::Engine.hash_secret(params[:password], password_salt)  
  client.exec_params("INSERT INTO users (name, email, password_salt, password_hash) VALUES ($1, $2, $3, $4)", [name, email, password_salt, password_hash])
  user = client.exec_params("SELECT * from users WHERE email = $1 AND password_hash = $2", [email, BCrypt::Engine.hash_secret(params[:password], password_salt)]).to_a.first
  session[:user] = user
  return redirect '/ingredients'
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
  user = client.exec_params("SELECT * FROM users WHERE password_hash = $1", [BCrypt::Engine.hash_secret(password, tmpUser['password_salt'])]).to_a.first if tmpUser
  if user.nil?
    return erb :signin
  else
    session[:user] = user
    return redirect '/ingredients'
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

get '/ingredients/:id/edit' do
  csrf_token_generate
  ingredient_id = params[:id]
  @ingredient = client.exec_params("SELECT * FROM ingredients WHERE id = #{ingredient_id}").to_a.first  
  return erb :ingredient_edit
end

delete "/ingredients/:id" do    
  ingredient_id = params[:id]    
  client.exec_params("DELETE FROM ingredients WHERE id = #{ingredient_id}")
  return redirect "/ingredients" 
end

put "/ingredients/:id" do
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

get '/recipes' do
  id = session[:user]['id']
  @recipes = client.exec_params("SELECT * FROM recipes WHERE user_id = #{id} ORDER BY name").to_a
  return erb :recipes
end

get '/recipes/new' do
  csrf_token_generate
  id = session[:user]['id']  
  @ingredients = client.exec_params("SELECT * FROM ingredients WHERE user_id = #{id} ORDER BY name").to_a
  @s_traders = client.exec_params("SELECT DISTINCT trader FROM ingredients WHERE user_id = #{id} ORDER BY trader").to_a  
  return erb :recipe_new
end

get '/recipes/:id' do
  user_id = session[:user]['id']
  recipe_id = params[:id]
  @recipe = client.exec_params("SELECT * FROM recipes WHERE id = $1 AND user_id = $2", [recipe_id, user_id]).to_a
  @ingredients = client.exec_params("
    SELECT
      ir.id
      , ir.meisai_id
      , ir.ingredient_id
      , ing.name
      , ing.unit_used
      , ir.amount
      , ir.cost_used
    FROM
      recipes as re
    inner join ingredient_recipes as ir 
      on re.id = ir.id 
    left join ingredients ing 
      on ir.ingredient_id = ing.id 
    WHERE
      re.id = $1 
    AND re.user_id = $2", [recipe_id, user_id]).to_a
  return erb :recipe
end
  
post "/recipes" do
  return redirect '/recipe/new' unless params[:csrf_token] == session[:csrf_token]
  form do
    field :name, :present => true, :length => 1..50
    field :price, :present => true   
  end
  if form.failed?
    output = erb :recipe_new
    fill_in_form(output)
  else
    name = params[:name]
    price = params[:price]
    description = params[:description]
    cost = 0
    user_id = session[:user]['id']    
    if !params[:img].nil?
      image = params[:img][:filename]
      tempfile = params[:img][:tempfile]
      save_to = "./public/images/#{image}"
      FileUtils.mv(tempfile, save_to)
    else
      image = 'default_20210226203011.png'
    end
    
    ingredients = []
    tmp = {}
    params.each do |key, value|
      split = key.split('_')
      if split[0] == 'ingredient'
        tmp[split[1]] = value        
        if split[1] == 'cost'
          ingredients.push(tmp)          
          cost += value.to_i
          tmp = {}
        end
      end
    end

    cost_rate = cost.to_f / price.to_f * 100
 
    client.exec_params(
      "INSERT INTO recipes (name, image, description, price, cost, cost_rate, user_id)
      VALUES ($1, $2, $3, $4, $5, $6, $7)",
      [name, image, description, price, cost, cost_rate, user_id]
    )

    recipe_id = client.exec_params("SELECT id FROM recipes WHERE name = $1 AND user_id = $2", [name, user_id]).to_a.first
    ingredients.each do |key, value|
      ingredient_id = key['id']
      amount = key['amount']
      cost_used = key['cost']
      meisai_id = client.exec_params(
        "SELECT max(meisai_id) as meisai_id FROM ingredient_recipes WHERE id = #{recipe_id['id']}"
      ).to_a.first
     
      meisai_id = {"meisai_id"=>0} if meisai_id['meisai_id'].nil?
      client.exec_params(
        "INSERT INTO ingredient_recipes (id, ingredient_id, amount, cost_used, user_id, meisai_id)
        VALUES ($1, $2, $3, $4, $5, $6)",
        [recipe_id['id'], ingredient_id, amount, cost_used, user_id, meisai_id['meisai_id'].to_i + 1]
      )
    end
    
    return redirect "/recipes/#{recipe_id['id']}"
  end
end
  
get '/recipes/:id/edit' do
  csrf_token_generate
  recipe_id = params[:id]
  user_id = session[:user]['id']
  @recipe = client.exec_params("SELECT * FROM recipes WHERE id = #{recipe_id}").to_a.first
  @s_traders = client.exec_params("SELECT DISTINCT trader FROM ingredients WHERE user_id = #{user_id} ORDER BY trader").to_a 
  @ingredients = client.exec_params("
    SELECT
      ir.id
      , ir.meisai_id
      , ir.ingredient_id
      , ing.name
      , ing.unit_used
      , ing.trader
      , ir.amount
      , ir.cost_used
    FROM
      recipes as re
    inner join ingredient_recipes as ir 
      on re.id = ir.id 
    left join ingredients ing 
      on ir.ingredient_id = ing.id 
    WHERE
      re.id = $1 
    AND re.user_id = $2", [recipe_id, user_id]).to_a

    @ingredient_name = []
    @ingredients.each_with_index do |ingredient, i|
      trader = ingredient['trader']
      @ingredient_name[i] = client.exec_params("SELECT id, name FROM ingredients WHERE trader = '#{trader}' AND user_id = #{user_id}").to_a
    end
    
  return erb :recipe_edit
end
  
delete "/recipes/:id" do    
  recipe_id = params[:id]    
  client.exec_params("DELETE FROM recipes WHERE id = #{recipe_id}")
  return redirect "/recipes" 
end
  
put "/recipes/:id" do
  return redirect '/recipe_new' unless params[:csrf_token] == session[:csrf_token]
  if form.failed?
    output = erb :recipe_new
    fill_in_form(output)
  else
    name = params[:name]
    price = params[:price]
    description = params[:description]
    cost = 0
    recipe_id = params['id']
    user_id = session[:user]['id']    
    if !params[:img].nil?
      image = params[:img][:filename]
      tempfile = params[:img][:tempfile]
      save_to = "./public/images/#{image}"
      FileUtils.mv(tempfile, save_to)
    end
    
    ingredients = []
    tmp = {}
    params.each do |key, value|
      split = key.split('_')
      if split[0] == 'ingredient'
        tmp[split[1]] = value        
        if split[1] == 'cost'
          ingredients.push(tmp)          
          cost += value.to_i
          tmp = {}
        end
      end
    end

    cost_rate = cost.to_f / price.to_f * 100
    
    client.exec_params(
      "UPDATE recipes
       SET name = $1, image = $2, description = $3, price = $4, cost = $5, cost_rate = $6, user_id = $7
       WHERE id = #{recipe_id} AND user_id = #{user_id}",
      [name, image, description, price, cost, cost_rate, user_id]
    )

    ingredients.each do |key, value|
      ingredient_id = key['id']
      amount = key['amount']
      cost_used = key['cost']
      meisai_id = key['meisai']
      
      if meisai_id.nil? 
        meisai_id = client.exec_params(
          "SELECT max(meisai_id) as meisai_id FROM ingredient_recipes WHERE id = #{recipe_id}"
        ).to_a.first
      
        client.exec_params(
          "INSERT INTO ingredient_recipes (id, ingredient_id, amount, cost_used, user_id, meisai_id)
          VALUES ($1, $2, $3, $4, $5, $6)",
          [recipe_id, ingredient_id, amount, cost_used, user_id, meisai_id['meisai_id'].to_i + 1]
        )
      else
        client.exec_params(
          "UPDATE ingredient_recipes
          SET ingredient_id = $1, amount = $2, cost_used = $3
          WHERE id = $4 AND meisai_id = $5",
          [ingredient_id, amount, cost_used, recipe_id, meisai_id]
        )
      end
    end
    
    return redirect "/recipes/#{recipe_id}"
  end
end

post '/sp_getingredient_name/:trader' do
  trader = params[:trader]
  user_id = session[:user]['id']
  ingredient_name = client.exec_params("SELECT id, name FROM ingredients WHERE trader = '#{trader}' AND user_id = #{user_id} ORDER BY name").to_a  
  return json ingredient_name
end

post '/sp_getingredient_unit/:id' do
  ingredient_id = params[:id]
  user_id = session[:user]['id']
  ingredient = client.exec_params("SELECT unit_used FROM ingredients WHERE id = #{ingredient_id} AND user_id = #{user_id}").to_a  
  return json ingredient
end

post '/sp_getingredient_cost/:id' do
  ingredient_id = params[:id]
  user_id = session[:user]['id']
  ingredient = client.exec_params("SELECT cost_used FROM ingredients WHERE id = #{ingredient_id} AND user_id = #{user_id}").to_a  
  return json ingredient
end

