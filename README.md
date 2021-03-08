# COSTMAN
原価計算付きのレシピ管理アプリ
### 動作サンプル
https://radiant-peak-23854.herokuapp.com/
### 設計書
https://docs.google.com/spreadsheets/d/1IRKC8JB2FQu8AjJxnbKWI9oK6l8EikTQ_d6DM5KSC_E/edit?usp=sharing

# ブランチ切り替え
### master
本番環境用ブランチ。
### develop
開発環境用ブランチ。手元でアプリを動かしたい場合、このブランチをCloneする。
### noDesign
cssを適用していない、divタグで並べただけのブランチ。プログラム部分のみ見たい場合に使用する。

# 自分のPCで動かす場合の手順
1. 適当にフォルダを作り、そこにdevelopブランチまたはnoDesignブランチをcloneする。 `$ git clone -b https://github.com/inamine007/sinatra_costman.git .`
2. `$ bundle install --path vendor/bundle`を実行
3. 使用するDBを用意する。`$ psql -d postgres`→`$ CREATE DATABASE sample`
4. sql/setup.sqlをエディタで開き、ユーザーがdevに設定されているので自分のユーザー名に全て置換する。(VSCodeでCommand + Fで検索、置換(mac))
5. `$ cd sql`でsqlフォルダに移動し、`$ psql sample < setup.sql`を実行
6. app.rbファイルがある階層に戻って`$ bundle exec ruby.rb`でsinatra起動
7. できなかったらすいません、、

# 未実装
- 食材を編集した際に紐付いているレシピも同時に更新。
- CSRF_TOKENがたまに一致せずPOSTできない。未解決。
- 食材詳細ページで編集ボタンをクリックすると数回に一度削除処理になる謎の動作がおこる。とりあえず編集ボタンを設置しないでおく。
