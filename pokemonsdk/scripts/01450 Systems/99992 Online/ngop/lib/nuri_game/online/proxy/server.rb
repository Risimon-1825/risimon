require "nuri_game/online/proxy/version"
require "nuri_game/online/proxy/packet"
require "socket"

module NuriGame
  module Online
    module Proxy
      # Server that connects the server together
      #
      # How to use a server
      #   server = NuriGame::Online::Proxy::Server.new("0.0.0.0", 3205)
      #   server.start # Start listening
      class Server
        # List of processed packet from client
        PROCESSED_PACKETS = [Packet::REGISTER, Packet::SEND_DATA_REQUEST, Packet::LIST_USER_REQUEST, Packet::FIND_USER_REQUEST, Packet::FIND_USER_BY_NAME_REQUEST]
        # Create a new server
        # @param ip [String] IP of the server
        # @param port [Integer] port of the server
        def initialize(ip, port)
          @server = TCPServer.new(ip, port)
          @sockets = Hash.new
          @users = Hash.new
          @user_db_mutex = Mutex.new
        end

        # Start server processing
        def start
          loop { Thread.start(@server.accept) { |client| process_client(client) } }
        end

        private

        # Process the client
        # @param client [TCPSocket]
        def process_client(client)
          id = -1
          id = connect_user(client)
          while (packet = read_client_packet(client))
            send(:"process_packet_#{packet.id}", id, packet.data) if PROCESSED_PACKETS.include?(packet.id)
          end
        ensure
          remove_user(id)
          client.close
        end

        # Connect a client and send it its id
        # @param client [TCPSocket]
        def connect_user(client)
          @user_db_mutex.synchronize do
            begin
              id = rand(0xFFFFFF)
            end while @sockets.has_key?(id)
            @sockets[id] = client
            client.write(Packet.new(packet_id: Packet::ID, id: id))
            return id
          end
        end

        # Remove a client from the proxy informations
        # @param id [Integer]
        def remove_user(id)
          @user_db_mutex.synchronize do
            @users.delete(id)
            @sockets.delete(id)
            packet = Packet.new(packet_id: Packet::DISCONNECTION, id: id)
            @sockets.each_value { |client| send_packet_to(client, packet) }
          end
        end

        # Safely send a packet to a client
        # @param client [TCPSocket]
        # @param packet [Packet]
        def send_packet_to(client, packet)
          client.write(packet) if client
        rescue StandardError
          # Safety in case the client disconnected during a lock
        end

        # Try to read a packet from a client
        # @param client [TCPSocket]
        # @return [Packet, nil]
        def read_client_packet(client)
          packet = Packet.new(client.read(5))
          data = client.read(size = packet.size)
          data << client.read(size - data.size) while data.size < size
          packet << data
          return packet
        rescue StandardError
          return nil
        end

        # Process REGISTER packet
        # @param id [Integer] id of the client
        # @param data [Hash] request info
        def process_packet_2(id, data)
          @user_db_mutex.synchronize do
            unless @users.has_key?(id)
              packet = Packet.new(packet_id: Packet::NEW_USER, id: id, name: data[:name])
              @users.each_key { |user_id| send_packet_to(@sockets[user_id], packet) }
            end
            @users[id] = { secret: data[:secret], name: data[:name] }
          end
        end

        # Process LIST_USER_REQUEST packet
        # @param id [Integer] id of the client
        # @param data [Hash] request info
        def process_packet_4(id, data)
          @user_db_mutex.synchronize do
            response = Hash.new
            @users.each { |user_id, user| response[user_id] = user[:name] }
            packet = Packet.new(packet_id: Packet::LIST_USER_RESPONSE, response: response)
            send_packet_to(@sockets[id], packet)
          end
        end

        # Process SEND_DATA_REQUEST packet
        # @param id [Integer] id of the client
        # @param data [Hash] request info
        def process_packet_6(id, data)
          packet = Packet.new(packet_id: Packet::RECEIVED_DATA, from: id, data: data[:data])
          data[:to].each { |user_id| send_packet_to(@sockets[user_id], packet) }
        end

        # Process FIND_USER_REQUEST packet
        # @param id [Integer] id of the client
        # @param data [Hash] request info
        def process_packet_9(id, data)
          @user_db_mutex.synchronize do
            found_id = @users.key({ secret: data[:secret], name: data[:name] }) || -1
            packet = Packet.new(packet_id: Packet::ID, id: found_id)
            send_packet_to(@sockets[id], packet)
          end
        end

        # Process FIND_USER_BY_NAME_REQUEST packet
        # @param id [Integer] id of the client
        # @param data [Hash] request info
        def process_packet_10(id, data)
          @user_db_mutex.synchronize do
            response = []
            name = data[:name]
            @users.each { |user_id, user| response << user_id if user[:name] == name }
            packet = Packet.new(packet_id: Packet::FIND_USER_BY_NAME_RESPONSE, response: response)
            send_packet_to(@sockets[id], packet)
          end
        end
      end
    end
  end
end