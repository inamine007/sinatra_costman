// 削除の確認ダイアログを表示
function delete_confirm() {
  if(!confirm('本当に削除してもよろしいですか?')) {
    return false;
  }
}

// tableの削除ボタンの処理
function table_delete(n) {
  if(confirm('本当に削除してもよろしいですか?')) {
    $('#form_' + n).submit();
  } else {
    return false;
  }
}

// 詳細ページの削除ボタンの処理
function shosai_delete() {
  if(confirm('本当に削除してもよろしいですか?')) {
    $('#deleteform').submit();
  } else {
    return false;
  }
}

// 退会削除ボタンの処理
function delete_user() {
  if(confirm('退会すると保存したデータは削除されます。本当に退会しますか?')) {
    $('#delete_user').submit();
  } else {
    return false;
  }
}

$(function(){
  $('.dropdwn li').hover(function(){
      $("ul:not(:animated)", this).slideDown();
  }, function(){
      $("ul.dropdwn_menu",this).slideUp();
  });
});