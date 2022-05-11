unless defined?(PSDK_CONFIG)
  require 'nuri_game/online/proxy/version'
  require 'nuri_game/online/proxy/packet'
  require 'socket'
end

module NuriGame
  module Online
    module Proxy
      # Client that connects to a Proxy Server
      #
      # How to use a Client
      #   client = NuriGame::Online::Proxy::Client.new
      #   is_connected = nil
      #   your_id = -1
      #   client.connect(ip, port) do |success, id|
      #     is_connected = success
      #     your_id = id
      #   end
      #   # Perform stuff waiting for is_connected being eq to true or false
      #   client.register(your_name, your_secret_code)
      #   # Finding a user
      #   his_id = -1
      #   user_found = nil
      #   client.find_user(his_name, his_secret_code) do |success, id|
      #     user_found = success
      #     his_id = id
      #   end
      #   # Perform stuff waiting for user_found to be eq to true or false
      #   client.on_data_received { |from_id, data| process_data(from_id, data) }
      #   # send data to the other user
      #   client.send_data('Hello there!', his_id)
      class Client
        # Error on client function call
        Error = Class.new(StandardError)
        # List of allowed packet to proceed
        PROCESSED_PACKETS = [Packet::ID, Packet::RECEIVED_DATA, Packet::NEW_USER, Packet::LIST_USER_RESPONSE, Packet::FIND_USER_BY_NAME_RESPONSE, Packet::DISCONNECTION]
        # @return [Integer] the current id of the client on the server
        attr_reader :id
        # Create a new client
        def initialize
          @id = -1
          @connected = false
          @awaiting_response = Mutex.new
          @request_mutex = false
          @awaiting_packet_id = -1
          # @return [TCPSocket]
          @socket = nil
        end

        # Disconnect from the server
        def disconnect
          raise Error, 'Not connected' unless connected?
          @connected = false
          @socket.close
        end

        # Check if the client is connected
        # @return [Boolean]
        def connected?
          return @connected
        end

        # Attempts to connect to a proxy server
        # @param ip_addr [String] IP of the server
        # @param port [Integer] port of the server
        # @parma connexion_block [Proc] the block to pass to transmit the connexion success or failure
        # @yieldparam connected [Boolean] if the connection is successfull
        # @yieldparam id [Integer] current ID of the client
        def connect(ip_addr, port, &connexion_block)
          Thread.start do
            @awaiting_response.synchronize do
              proceed_connection(ip_addr, port, &connexion_block)
              listen if connected?
            end
          end
        end

        # Try to find the id of an user knowing its name and its secret
        # @example client.find_user('Name', secret_number) { |success, id| do_somethind_with_id_if_success }
        # @param name [String] name of the user to find
        # @parma secret [Integer] secret code of the user to find
        # @yieldparam success [Boolean] if the operation was successfull
        # @yieldparam id [Integer] ID of the retrieved user
        def find_user(name, secret, &block)
          raise Error, 'Not connected' unless connected?
          raise Error, 'Invalid block arity. The block should have two required parameters.' if !block || block.arity != 2
          raise Error, 'Waiting for an other request' if @request_mutex
          @on_find_user = block
          @socket.write(Packet.new(packet_id: Packet::FIND_USER_REQUEST, name: name, secret: secret))
          mutex_lock(Packet::ID)
        end

        # Try to list all the user of the server
        # @example client.list_user { |success, id_list| do_somethind_with_id_list }
        # @yieldparam success [Boolean] if the operation was successfull
        # @yieldparam id_list [Array<Integer>] list of ids
        def list_user(&block)
          raise Error, 'Not connected' unless connected?
          raise Error, 'Invalid block arity. The block should have two required parameters.' if !block || block.arity != 2
          raise Error, 'Waiting for an other request' if @request_mutex
          @on_user_list = block
          @socket.write(Packet.new(packet_id: Packet::LIST_USER_REQUEST))
          mutex_lock(Packet::LIST_USER_RESPONSE)
        end

        # Tell what to do when a user connects to the server
        # @example client.on_user_connect { |id, name| do_somethind_with_id }
        # @yieldparam id [Integer] ID of the user
        # @yieldparam name [String] name of the user
        def on_user_connect(&block)
          raise Error, 'Not connected' unless connected?
          raise Error, 'Invalid block arity. The block should have two required parameters.' if !block || block.arity != 2
          @on_user_connect = block
        end

        # Send data to other clients
        # @example client.send_data('data', his_id)
        # @param data [String] the data
        # @param ids [Array<Integer>] list of ids that should receive the data
        def send_data(data, *ids)
          raise Error, 'Not connected' unless connected?
          @socket.write(Packet.new(packet_id: Packet::SEND_DATA_REQUEST, to: ids, data: data))
        end

        # Do something when the client receive data from someone
        # @example client.on_data_received { |from_id, data| do_something_with_data }
        # @yieldparam from_id [Integer] ID of the user who sent the data
        # @yieldparam data [String] data received
        def on_data_received(&block)
          raise Error, 'Not connected' unless connected?
          raise Error, 'Invalid block arity. The block should have two required parameters.' if !block || block.arity != 2
          @on_data_received = block
        end

        # Tell what to do when a user disconnects from the server
        # @example client.on_user_disconnect { |id| do_somethind_with_id }
        # @yieldparam id [Integer] ID of the client who disconnected
        def on_user_disconnect(&block)
          raise Error, 'Not connected' unless connected?
          raise Error, 'Invalid block arity. The block should have one required parameters.' if !block || block.arity != 1
          @on_user_disconnect = block
        end

        # Try to list all the user of the server that match a specific name
        # @example client.list_user_by_name(name) { |success, id_list| do_somethind_with_id_list }
        # @param name [String]
        # @yieldparam success [Boolean] if the operation was successfull
        # @yieldparam id_list [Array<Integer>] list of user ids
        def list_user_by_name(name, &block)
          raise Error, 'Not connected' unless connected?
          raise Error, 'Invalid block arity. The block should have two required parameters.' if !block || block.arity != 2
          raise Error, 'Waiting for an other request' if @request_mutex
          @on_user_list_by_name = block
          @socket.write(Packet.new(packet_id: Packet::FIND_USER_BY_NAME_REQUEST, name: name))
          mutex_lock(Packet::FIND_USER_BY_NAME_RESPONSE)
        end

        # Register the client to the server so the other clients will know
        # @param name [String] name of the client
        # @parma secret [Integer] secret code of the client
        def register(name, secret)
          raise Error, 'Not connected' unless connected?
          @socket.write(Packet.new(packet_id: Packet::REGISTER, name: name, secret: secret))
        end

        private

        # Listen to the incomming packets and call the right blocs
        def listen
          raise Error, 'Not connected' unless connected?
          Thread.start(@socket) { |socket| listen_to(socket) }
        end

        # Listend to a specific socket
        # @param socket [TCPSocket]
        def listen_to(socket)
          while (packet = read_packet(socket))
            send(:"proceed_received_packet_#{packet.id}", packet.data) if PROCESSED_PACKETS.include?(packet.id)
          end
        ensure
          @connected = false
          @request_mutex = false if @request_mutex
          socket.close
        end

        # Try to unlock the mutex
        # @param packet_id [Integer] id of the packet that was expected to be received when locking the mutex
        def mutex_unlock_attempt(packet_id)
          @request_mutex = false if @request_mutex && packet_id == @awaiting_packet_id
        end

        # Lock the mutex with a packet id
        # @param packet_id [Integer] id of the packet that should be received to unlock the mutex
        def mutex_lock(packet_id)
          @request_mutex = true
          @awaiting_packet_id = packet_id
        end

        # Perform the real connexion
        # @param ip_addr [String] IP of the server
        # @param port [Integer] port of the server
        def proceed_connection(ip_addr, port)
          raise Error, 'Already connected' if connected?
          @socket = TCPSocket.new(ip_addr, port)
          packet = read_packet(@socket)
          if packet && packet.id == Packet::ID
            yield(@connected = true, @id = packet.data[:id]) if block_given?
          elsif block_given?
            yield(false, -1)
          end
        rescue StandardError
          yield(false, -1) if block_given?
        end

        # Try to read a packet from a socket
        # @param socket [TCPSocket]
        # @return [Packet, nil]
        def read_packet(socket)
          packet = Packet.new(socket.read(5))
          data = socket.read(size = packet.size)
          data << socket.read(size - data.size) while data.size < size
          packet << data
          return packet
        rescue StandardError
          return nil
        end

        # Proceed an incomming ID packet
        # @param data [Hash]
        def proceed_received_packet_1(data)
          mutex_unlock_attempt(Packet::ID)
          @on_find_user.call(data[:id] >= 0, data[:id]) if @on_find_user
        end

        # Proceed an incomming NEW_USER packet
        # @param data [Hash]
        def proceed_received_packet_3(data)
          mutex_unlock_attempt(Packet::NEW_USER)
          @on_user_connect.call(data[:id], data[:name]) if @on_user_connect
        end

        # Proceed an incomming LIST_USER_RESPONSE packet
        # @param data [Hash]
        def proceed_received_packet_5(data)
          mutex_unlock_attempt(Packet::LIST_USER_RESPONSE)
          response = data[:response]
          @on_user_list.call(!response.empty?, response) if @on_user_list
        end

        # Proceed an incomming RECEIVED_DATA packet
        # @param data [Hash]
        def proceed_received_packet_7(data)
          mutex_unlock_attempt(Packet::RECEIVED_DATA)
          @on_data_received.call(data[:from], data[:data]) if @on_data_received
        end

        # Proceed an incomming DISCONNECTION packet
        # @param data [Hash]
        def proceed_received_packet_8(data)
          mutex_unlock_attempt(Packet::DISCONNECTION)
          @on_user_disconnect.call(data[:id]) if @on_user_disconnect
        end

        # Proceed an incomming FIND_USER_BY_NAME_RESPONSE packet
        # @param data [Hash]
        def proceed_received_packet_11(data)
          mutex_unlock_attempt(Packet::FIND_USER_BY_NAME_RESPONSE)
          response = data[:response]
          @on_user_list_by_name.call(!response.empty?, response) if @on_user_list_by_name
        end
      end
    end
  end
end
