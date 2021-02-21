require 'bcrypt'

module Escape
  def h(text)
    Rack::Utils.escape_html(text)
  end

  def csrf_token_generate
    str = SecureRandom.base64(64)
    @csrf_token = BCrypt::Password.create(str)   
    session[:csrf_token] = @csrf_token
  end
end