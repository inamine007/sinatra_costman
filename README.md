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
1. 適当にフォルダを作り、そこにdevelopブランチまたはnoDesignブランチをcloneする。
2. `$ bundle install --path vendor/bundle`を実行
3. 使用するDBを用意する。
4. sql/setup.sqlをエディタで開き、ユーザーがdevに設定されているので自分のユーザー名に全て置換する。
5. sqlフォルダに移動し、`$ psql 使用するdatabase名 < setup.sql`を実行
