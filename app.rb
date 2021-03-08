# -----gem読み込み-----
require 'sinatra'
require 'sinatra/reloader' # ブラウザのリロードで変更が反映される
require 'sinatra/json' # Ajax通信で必要
require 'pry' # デバッグで必要
require 'bcrypt' # 暗号化
require 'pg' # postgresと接続
require 'date' #日時情報を取得
require './helpers/helpers.rb' # ヘルパーファイル読み込み

# -----各種設定-----
configure do
  enable :sessions
  helpers Escape
end

# -----DB接続設定-----
client = PG::connect(
  :host => ENV.fetch("HOST", "localhost"),
  :user => ENV.fetch("USER"),
  :password => ENV.fetch("PASSWORD"),
  :dbname => ENV.fetch("DBNAME")
)

# -----共通処理-----
before do
  if request.request_method == 'GET' 
    # フォームにcsrf_token設置   
    csrf_token_generate
  end

  if session[:user]
    # ログインしてれば'/top'に遷移させる 
    if request.path == '/' || request.path == '/signin' || request.path == '/signup'
      redirect '/top'
    end
  else # ログインしていなければ'/signin'に遷移させる 
    unless request.path == '/' || request.path == '/signin' || request.path == '/signup'
      session[:notice] = { class:"r-flash flash", message: "ログインして下さい"} 
      redirect '/signin'
    end
  end
  
  # ログインしていればsessionからユーザー名を取得
  @name = session[:user]['name'] if session[:user]

  # ---フォームで必要な項目を生成---
  # 単位
  @s_unit= {'Kg': '0', '100g': '1', 'g': '2', 'L': '3', '100ml': '4', 'ml': '5', '個': '6', '本': '7', '袋': '8'}
  # 歩留まり
  @s_budomari = ['1', '0.9', '0.8', '0.7', '0.6', '0.5', '0.4', '0.3', '0.2', '0.1']
  # 換算数
  @s_converted_number = ['1', '0.1', '0.01', '0.001']

  # フラッシュメッセージ
  @message = session.delete(:notice)

end

# -----ルーティング-----

# ---ルートページ---
get '/' do
  # 特に処理はなし。erb返すだけ
  return erb :index
end

get '/top' do
  # 特に処理はなし。erb返すだけ
  return erb :top
end

# ---新規登録ページ---
get '/signup' do
  # 特に処理はなし。erb返すだけ
  return erb :signup
end

# ---新規登録処理---
post '/signup' do
  name = params[:name]
  email = params[:email]
  # パスワード生成処理。まずはsaltを生成
  password_salt = BCrypt::Engine.generate_salt
  # 受け取ったpasswordと生成したsaltを使ってパスワードを生成
  password_hash = BCrypt::Engine.hash_secret(params[:password], password_salt)
  begin
    # DBにユーザーを新規追加し、同時にreturningで結果を取得してログイン処理をする
    user = client.exec_params("INSERT INTO users (name, email, password_salt, password_hash) VALUES ($1, $2, $3, $4) returning *", [name, email, password_salt, password_hash]).to_a.first
    session[:user] = user
    # sessionに成功メッセージを格納し、トップページにリダイレクト
    session[:notice] = { class: "b-flash flash", message:"ようこそ！#{user['name']}さん!"}
    return redirect '/top'
  rescue PG::UniqueViolation #例外処理 メールアドレスがかぶっている場合
    session[:notice] = { class: "r-flash flash", message:"入力したメールアドレスはすでに使用されています。"}
    return redirect '/signup'
  end
end

# ---ログインページ---
get "/signin" do
  return erb :signin
end

# ---ログイン処理---
post "/signin" do
  email = params[:email]
  password = params[:password]
  # 一旦emailでユーザーを取得
  tmpUser = client.exec_params("SELECT * FROM users WHERE email = $1", [email]).to_a.first
  # 取得したユーザーのsaltと受け取ったpasswordを使ってパスワードを照合
  user = client.exec_params("SELECT * FROM users WHERE password_hash = $1", [BCrypt::Engine.hash_secret(password, tmpUser['password_salt'])]).to_a.first if tmpUser
  # ユーザーが取得できなければログインページに、取得できればsessionにユーザー情報を格納してトップページに遷移
  if user.nil?
    session[:notice] = { class: "r-flash flash", message:"ログインに失敗しました。"}
    return redirect '/signin'
  else
    session[:user] = user
    session[:notice] = { class: "b-flash flash", message: "ログインしました!"}
    return redirect '/top'
  end
end

# ---ログアウト処理---
delete "/signout" do
  unless params[:csrf_token] == session[:csrf_token]
    session[:notice] = { class: "r-flash flash", message:"入力を受け取れません。無効なフォームからの送信です。"}
    return redirect '/top'
  end  
  # ユーザーのセッション情報をクリアしルートページに遷移
  session[:user] = nil
  session[:notice] = { class: "b-flash flash", message:"ログアウトしました！"}
  return redirect '/'
end

# ---アカウント削除処理---
delete "/user" do
  unless params[:csrf_token] == session[:csrf_token]
    session[:notice] = { class: "r-flash flash", message:"入力を受け取れません。無効なフォームからの送信です。"}
    return redirect '/top'
  end  
  # セッションからユーザー情報を取得し、DBから対応するユーザーを削除
  user = session[:user]
  client.exec_params("DELETE FROM users WHERE email = $1 AND password_hash = $2", [user['email'], user['password_hash']]).to_a.first
  # ユーザーのセッション情報をクリアしルートページに遷移
  session[:user] = nil
  session[:notice] = { class: "b-flash flash", message:"アカウント削除しました。またのご利用お待ちしております。"}
  return redirect '/signin'
end

# ---食材一覧ページ---
get '/ingredients' do
  # セッションからユーザーidを取得し、ユーザーに紐付いている食材をDBから全て取得
  id = session[:user]['id']  
  @ingredients = client.exec_params("SELECT *, to_char(created_at, 'yyyy/mm/dd') as created FROM ingredients WHERE user_id = #{id} ORDER BY trader").to_a
  return erb :ingredients
end

# ---食材登録ページ---
get '/ingredients/new' do
  return erb :ingredient_new
end

# ---食材詳細ページ---
get '/ingredients/:id' do
  # URLから食材idを取得
  ingredient_id = params[:id]
  user_id = session[:user]['id']
  # 食材のidとユーザーのidから対応する食材をDBから取得
  @ingredient = client.exec_params("SELECT *, to_char(created_at, 'yyyy/mm/dd') as created FROM ingredients WHERE id = #{ingredient_id} AND user_id = #{user_id}").to_a.first
  # 食材が取得できない場合、食材一覧ページに遷移
  if @ingredient.nil?
    return redirect '/ingredients'
  end
  return erb :ingredient
end

# ---食材登録処理---
post "/ingredients" do
  unless params[:csrf_token] == session[:csrf_token]
    session[:notice] = { class: "r-flash flash", message:"入力を受け取れません。無効なフォームからの送信です。"}
    return redirect '/ingredients/new'
  end  
  name = params[:name]
  trader = params[:trader]
  unit = params[:unit]
  cost = params[:cost]
  budomari = params[:budomari]
  unit_used = params[:unit_used]
  converted_number = params[:converted_number]
  # 換算数、原価、歩留まりから使用単位あたりの原価を求める
  cost_used = converted_number.to_f * cost.to_f * (2 - budomari.to_f)
  user_id = session[:user]['id']
  # 受け取った内容をDBに反映
  client.exec_params(
    "INSERT INTO ingredients (name, trader, unit, cost, budomari, unit_used, converted_number, cost_used, user_id)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)",
    [name, trader, unit, cost, budomari, unit_used, converted_number, cost_used, user_id]
  )
  session[:notice] = { class: "b-flash flash", message:"#{name}を登録しました!"}
  return redirect '/ingredients'
end

# ---食材編集ページ---
get '/ingredients/:id/edit' do
  # URLから食材idを取得
  ingredient_id = params[:id]
  user_id = session[:user]['id']
  # 食材のidとユーザーのidから対応する食材をDBから取得
  @ingredient = client.exec_params("SELECT * FROM ingredients WHERE id = #{ingredient_id} AND user_id = #{user_id}").to_a.first
  # 食材が取得できない場合、食材一覧ページに遷移
  if @ingredient.nil?
    return redirect '/ingredients'
  end
  return erb :ingredient_edit
end

# ---食材削除処理---
delete "/ingredients/:id" do
  unless params[:csrf_token] == session[:csrf_token]
    session[:notice] = { class: "r-flash flash", message:"入力を受け取れません。無効なフォームからの送信です。"}
    return redirect '/ingredients/new'
  end  
  # URLから食材idを取得
  ingredient_id = params[:id]
  user_id = session[:user]['id']
  begin
    # トランザクション開始
    client.exec("BEGIN")
    # 食材のidとユーザーのidから対応する食材をDBから削除
    client.exec_params("DELETE FROM ingredients WHERE id = #{ingredient_id} AND user_id = #{user_id}")
    # 紐付いているレシピからも削除
    recipe_ids = client.exec_params("SELECT id FROM ingredient_recipes WHERE ingredient_id = #{ingredient_id} AND user_id = #{user_id}").to_a
    # 紐付いているレシピが存在する場合
    unless recipe_ids.nil?
      client.exec_params("DELETE FROM ingredient_recipes WHERE ingredient_id = #{ingredient_id} AND user_id = #{user_id}")

      recipe_ids.each do |recipe_id|
        r_costs = client.exec_params("SELECT cost_used FROM ingredient_recipes WHERE id = #{recipe_id['id']} AND user_id = #{user_id}").to_a
        r_cost = 0
        r_costs.each do |value|
          r_cost += value['cost_used'].to_i
        end
        
        client.exec_params(
          "UPDATE recipes
          SET cost = #{r_cost}, cost_rate = #{r_cost.to_f} / price * 100
          WHERE id = #{recipe_id['id']} AND user_id = #{user_id}",
        )
      end
    end
    session[:notice] = { class: "b-flash flash", message:"削除しました。"}
    return redirect "/ingredients"
  rescue
    # エラーがあれば処理を全てキャンセルする
    session[:notice] = { class: "r-flash flash", message: "更新できませんでした。もう一度やり直して下さい。"}
    client.exec("ROLLBACK")
    return redirect "/ingredients/#{ingredient_id}"
  end
end

# ---食材編集処理---
put "/ingredients/:id" do
  unless params[:csrf_token] == session[:csrf_token]
    session[:notice] = { class: "r-flash flash", message:"入力を受け取れません。無効なフォームからの送信です。"}
    return redirect '/ingredients/new'
  end  
  user_id = session[:user]['id']
  ingredient_id = params[:id]
  name = params[:name]
  trader = params[:trader]
  unit = params[:unit]
  cost = params[:cost]
  budomari = params[:budomari]
  unit_used = params[:unit_used]
  converted_number = params[:converted_number] 
  # 換算数、原価、歩留まりから使用単位あたりの原価を求める 
  cost_used = converted_number.to_f * cost.to_f * (2 - budomari.to_f)

  # 対応する食材を更新 
  client.exec_params(
    "UPDATE ingredients
    SET name = $1, trader = $2, unit = $3, cost = $4, budomari = $5, unit_used = $6, converted_number = $7, cost_used = $8
    WHERE id = #{ingredient_id}",
    [name, trader, unit, cost, budomari, unit_used, converted_number, cost_used]
  )
  session[:notice] = { class: "b-flash flash", message:"#{name}を編集しました。"}
  return redirect "/ingredients/#{ingredient_id}"
end

# ---レシピ一覧ページ---
get '/recipes' do
  # セッションからユーザーidを取得し、ユーザーに紐付いているレシピをDBから全て取得
  id = session[:user]['id']
  @recipes = client.exec_params("SELECT *, to_char(created_at, 'yyyy/mm/dd') as created FROM recipes WHERE user_id = #{id} ORDER BY name").to_a
  return erb :recipes
end

# ---レシピ登録ページ---
get '/recipes/new' do
  id = session[:user]['id']
  # レシピには食材も登録させるのでユーザーに紐付いている食材をDBから全て取得  
  @ingredients = client.exec_params("SELECT * FROM ingredients WHERE user_id = #{id} ORDER BY name").to_a
  # 選択項目で使用する仕入先を全て取得
  @s_traders = client.exec_params("SELECT DISTINCT trader FROM ingredients WHERE user_id = #{id} ORDER BY trader").to_a  
  return erb :recipe_new
end

# ---レシピ詳細ページ---
get '/recipes/:id' do
  user_id = session[:user]['id']
  # URLからレシピidを取得
  recipe_id = params[:id]
  # レシピのidとユーザーのidから対応するレシピをDBから取得
  @recipe = client.exec_params("SELECT *, to_char(created_at, 'yyyy/mm/dd') as created FROM recipes WHERE id = #{recipe_id} AND user_id = #{user_id}").to_a.first
  # レシピが取得できない場合、レシピ一覧ページに遷移
  if @recipe.nil?
    return redirect '/recipes'
  end
  # レシピに紐付いている食材を取得。レシピと食材は多対多の関係なので中間テーブルとjoinする必要がある
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
  return erb :recipe
end
  
# ---レシピ作成処理---
post "/recipes" do
  unless params[:csrf_token] == session[:csrf_token]
    session[:notice] = { class: "r-flash flash", message:"入力を受け取れません。無効なフォームからの送信です。"}
    return redirect '/recipes/new'
  end  
  name = params[:name]
  price = params[:price]
  description = params[:description]
  cost = 0
  user_id = session[:user]['id']    
  # 画像保存処理
  if !params[:img].nil? # 画像を受け取った場合
    image = "#{Time.now.to_i}" + "#{params[:img][:filename]}" # 同一のファイル名だと上書きされるので、日時情報をつけて被らないようにする
    tempfile = params[:img][:tempfile] # デフォルトのファイル保存場所
    save_to = "./public/images/#{image}" # ファイルを保存したい場所
    FileUtils.mv(tempfile, save_to) # ファイルをデフォルトの場所から保存したい場所(public配下)に移動させる
  else
    # 画像を受け取らなかった場合、デフォルトの画像を設定する
    image = 'default_20210226203011.png'
  end
  
  # 受け取った食材情報を配列の形に加工する
  ingredients = [] # 食材情報を格納する空の配列を生成
  tmp = {} # 一時的に食材情報を格納するハッシュを生成
  params.each do |key, value| # 受け取ったデータを1つ1つ見る
    split = key.split('_') # ['ingredient', 'id', '0']みたいな形の配列になる
    if split[0] == 'ingredient' # ingredientという文字列を持っているデータの場合
      tmp[split[1]] = value # 食材のキーと値を一時ハッシュに追加
      if split[1] == 'cost' # 食材のキーがcostの場合
        ingredients.push(tmp) # 一時ハッシュを配列に入れる。[{'id': '21', 'amount': '12', 'cost': '120'}, {'id': '23', 'amount': '100', 'cost': '140'}, ]みたいな配列ができる
        cost += value.to_i # 食材の原価を足していく。合計がレシピの原価になる
        tmp = {} # 一時ハッシュをリセット
      end
    end
  end

  # レシピ原価と値段から原価率を求める
  cost_rate = cost.to_f / price.to_f * 100

  # レシピ保存処理。recipesテーブルの他に、中間テーブルのingredient_resipesテーブルにもデータを保存するのでトランザクションを使用する
  begin
    # トランザクション開始
    client.exec("BEGIN")
    # recipesテーブルにデータを保存し、同時にidを取得
    recipe_id = client.exec_params(
      "INSERT INTO recipes (name, image, description, price, cost, cost_rate, user_id)
      VALUES ($1, $2, $3, $4, $5, $6, $7) returning id",
      [name, image, description, price, cost, cost_rate, user_id]
    ).to_a.first

    # recipe_id = client.exec_params("SELECT id FROM recipes WHERE name = $1 AND user_id = $2", [name, user_id]).to_a.first
    
    ingredients.each do |key, value|
      ingredient_id = key['id']
      amount = key['amount']
      cost_used = key['cost']
      # meisai_idの最大値を取得
      meisai_id = client.exec_params(
        "SELECT max(meisai_id) as meisai_id FROM ingredient_recipes WHERE id = #{recipe_id['id']}"
      ).to_a.first
      
      # meisai_idがない場合、0に設定
      meisai_id = {"meisai_id"=>0} if meisai_id['meisai_id'].nil?
      # 中間テーブルにデータを保存
      client.exec_params(
        "INSERT INTO ingredient_recipes (id, ingredient_id, amount, cost_used, user_id, meisai_id)
        VALUES ($1, $2, $3, $4, $5, $6)",
        [recipe_id['id'], ingredient_id, amount, cost_used, user_id, meisai_id['meisai_id'].to_i + 1]
      )
    end
    # エラーがなければトランザクションを終了し、DBに反映
    client.exec("COMMIT")
    session[:notice] = { class: "b-flash flash", message:"#{name}を登録しました。"}
    return redirect "/recipes/#{recipe_id['id']}"
  rescue
    # エラーがあれば処理を全てキャンセルする
    session[:notice] = { class: "r-flash flash", message: "登録できませんでした。もう一度やり直して下さい。"}
    client.exec("ROLLBACK")
    return redirect "/recipes/new"
  end
end
    
# ---レシピ編集ページ---
get '/recipes/:id/edit' do
  # URLからレシピidを取得
  recipe_id = params[:id]
  user_id = session[:user]['id']
  # レシピのidとユーザーのidから対応するレシピをDBから取得
  @recipe = client.exec_params("SELECT * FROM recipes WHERE id = #{recipe_id} AND user_id = #{user_id}").to_a.first
  # レシピが取得できない場合、レシピ一覧ページに遷移
  if @recipe.nil?
    return redirect '/recipes'
  end
  # 選択項目で使用する仕入先を全て取得
  @s_traders = client.exec_params("SELECT DISTINCT trader FROM ingredients WHERE user_id = #{user_id} ORDER BY trader").to_a
  # レシピに紐付いている食材を取得。レシピと食材は多対多の関係なので中間テーブルとjoinする必要がある
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
    # 選択項目で使用する食材情報を配列に格納
    @ingredients.each_with_index do |ingredient, i|
      trader = ingredient['trader']
      @ingredient_name[i] = client.exec_params("SELECT id, name FROM ingredients WHERE trader = '#{trader}' AND user_id = #{user_id}").to_a
    end
  return erb :recipe_edit
end
  
# ---レシピ削除機能---
delete "/recipes/:id" do
  unless params[:csrf_token] == session[:csrf_token]
    session[:notice] = { class: "r-flash flash", message:"入力を受け取れません。無効なフォームからの送信です。"}
    return redirect '/recipes/new'
  end
  recipe_id = params[:id]
  # レシピ削除処理。recipesテーブルの他に、中間テーブルのingredient_resipesテーブルにもデータを削除するのでトランザクションを使用する
  begin
    client.exec("BEGIN")
    client.exec_params("DELETE FROM recipes WHERE id = #{recipe_id}")
    client.exec_params("DELETE FROM ingredient_recipes WHERE id = #{recipe_id}")
    session[:notice] = { class: "r-flash flash", message:"削除しました。"}
    client.exec("COMMIT")
    return redirect "/recipes"
  rescue
    session[:notice] = { class: "r-flash flash", message:"削除に失敗しました。"}
    client.exec("ROLLBACK")
    return redirect "/recipes/#{recipe_id}"
  end
end
  
# ---レシピ編集処理---
put "/recipes/:id" do
  unless params[:csrf_token] == session[:csrf_token]
    session[:notice] = { class: "r-flash flash", message:"入力を受け取れません。無効なフォームからの送信です。"}
    return redirect '/recipes/new'
  end  

  name = params[:name]
  price = params[:price]
  description = params[:description]
  cost = 0
  recipe_id = params['id']
  user_id = session[:user]['id']    
  # 画像の変更があった場合
  if !params[:update_img].nil?
    image = "#{Time.now.to_i}" + "#{params[:update_img][:filename]}"
    tempfile = params[:update_img][:tempfile]
    save_to = "./public/images/#{image}"
    FileUtils.mv(tempfile, save_to)
  else
    # 画像の変更がなかった場合、元の画像を隠しフォームから受け取る
    image = params[:img]
  end
  
  # -以下は登録処理とほぼ同じ-

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

  # binding.pry

  cost_rate = cost.to_f / price.to_f * 100
  
  begin
    client.exec("BEGIN")    
    client.exec_params(
      "UPDATE recipes
        SET name = $1, image = $2, description = $3, price = $4, cost = $5, cost_rate = $6, user_id = $7
        WHERE id = #{recipe_id} AND user_id = #{user_id}",
      [name, image, description, price, cost, cost_rate, user_id]
    )

    # 食材をリセット
    client.exec_params(
      "DELETE FROM ingredient_recipes WHERE id = #{recipe_id}"
    )

    ingredients.each do |key, value|
      ingredient_id = key['id']
      amount = key['amount']
      cost_used = key['cost']
      # meisai_idの最大値を取得
      meisai_id = client.exec_params(
        "SELECT max(meisai_id) as meisai_id FROM ingredient_recipes WHERE id = #{recipe_id}"
      ).to_a.first
      
      # meisai_idがない場合、0に設定
      meisai_id = {"meisai_id"=>0} if meisai_id['meisai_id'].nil?
      # 中間テーブルにデータを保存
      client.exec_params(
        "INSERT INTO ingredient_recipes (id, ingredient_id, amount, cost_used, user_id, meisai_id)
        VALUES ($1, $2, $3, $4, $5, $6)",
        [recipe_id, ingredient_id, amount, cost_used, user_id, meisai_id['meisai_id'].to_i + 1]
      )
    end
    client.exec("COMMIT")
    session[:notice] = { class: "b-flash flash", message:"#{name}を編集しました。"}
    return redirect "/recipes/#{recipe_id}"
  rescue
    session[:notice] = { class: "r-flash flash", message: "更新できませんでした。もう一度やり直して下さい。" }
    client.exec("ROLLBACK")
    return redirect "/recipes/#{recipe_id}/edit"
  end
end

# -----Ajax通信-----

# ---仕入先に対応する食材名を取得---
post '/sp_getingredient_name/:trader' do
  unless params[:csrf_token] == session[:csrf_token]
    session[:notice] = { class: "r-flash flash", message:"入力を受け取れません。無効なフォームからの送信です。"}
    return redirect '/recipes/new'
  end  
  trader = params[:trader]
  user_id = session[:user]['id']
  ingredient_name = client.exec_params("SELECT id, name FROM ingredients WHERE trader = '#{trader}' AND user_id = #{user_id} ORDER BY name").to_a  
  # jsonで返す
  return json ingredient_name
end

# ---食材の使用単位を取得---
post '/sp_getingredient_unit/:id' do
  unless params[:csrf_token] == session[:csrf_token]
    session[:notice] = { class: "r-flash flash", message:"入力を受け取れません。無効なフォームからの送信です。"}
    return redirect '/recipes/new'
  end  
  ingredient_id = params[:id]
  user_id = session[:user]['id']
  ingredient = client.exec_params("SELECT unit_used FROM ingredients WHERE id = #{ingredient_id} AND user_id = #{user_id}").to_a  
  # jsonで返す
  return json ingredient
end

# ---食材の使用原価を取得---
post '/sp_getingredient_cost/:id' do
  unless params[:csrf_token] == session[:csrf_token]
    session[:notice] = { class: "r-flash flash", message:"入力を受け取れません。無効なフォームからの送信です。"}
    return redirect '/recipes/new'
  end  
  ingredient_id = params[:id]
  user_id = session[:user]['id']
  ingredient = client.exec_params("SELECT cost_used FROM ingredients WHERE id = #{ingredient_id} AND user_id = #{user_id}").to_a  
  # jsonで返す
  return json ingredient
end

