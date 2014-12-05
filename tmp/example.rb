load "../api_direct.rb"
@tevo = TEVO::Connection.new({
  :token  => "{your-token}",
  :secret => "{your-secret}"
})
