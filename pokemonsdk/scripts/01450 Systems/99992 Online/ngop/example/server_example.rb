require 'nuri_game/online/proxy/server'

server = NuriGame::Online::Proxy::Server.new('0.0.0.0', 3205)
puts "Listening"
begin
  server.start # Start listening
rescue Exception
  puts "Server got stopped! \n#{$!.class}"
end