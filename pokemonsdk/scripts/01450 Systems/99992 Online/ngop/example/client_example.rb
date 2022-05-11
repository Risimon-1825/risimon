require 'nuri_game/online/proxy/client'

client = NuriGame::Online::Proxy::Client.new

is_connected = false
mutex = true
puts 'Trying to connect...'

client.connect('127.0.0.1', 3205) do |success, id|
  is_connected = success
  if success
    puts("Your ID is #{id}")
  end
  mutex = false
end

sleep(1) while mutex

if is_connected
  print('Enter your name : ')
  name = gets.chomp
  print('Enter your secret : ')
  secret = gets.to_i
  client.register(name, secret)
  # Register all the listening stuff
  client.on_user_connect { |id, name| puts "#{name} connected with ID #{id}" }
  client.on_user_disconnect { |id| puts "#{id} disconnected" }
  client.on_data_received { |from_id, data| puts "#{from_id} sent #{data}" }
  
  while (line = gets.chomp).size > 0
    args = line.split(',')
    case args.first
    when 'find'
      client.find_user(args[1], args[2].to_i)  { |success, id| puts "User ID : #{id} (#{success})" }
    when 'send'
      client.send_data(args[2..-1].join(','), args[1].to_i)
    end
  end
  client.disconnect
else
  puts 'Failed to connect :/'
end