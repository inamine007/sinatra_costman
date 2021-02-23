$(function() {
  $('#delete_confirm').click(function() {
    var check = window.confirm('本当に削除してもよろしいですか?')
    if (!check) {
      return false;
    }
  });
});