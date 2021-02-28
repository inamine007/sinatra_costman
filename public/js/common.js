// 削除の確認ダイアログを表示
function delete_confirm() {
  if(!confirm('本当に削除してもよろしいですか?')) {
    return false;
  }
};