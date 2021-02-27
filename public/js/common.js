function delete_confirm() {
  if (!confirm('本当に削除してもよろしいですか?')) {
    return false;
  }
};