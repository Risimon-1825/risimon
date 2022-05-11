module NuriGame
  module Online
    module Proxy
      # Packet sent or received by the proxy server.
      # It can decode or construct packet to be sent online.
      #
      # How to decode a Packet
      #   packet = Packet.new socket.read(5)
      #   packet << socket.read(packet.size)
      #   print packet.data
      #
      # How to encode a Packet
      #   packet = Packet.new packet_id: Packet::ID, id: value
      #   socket.write(packet)
      #
      # All the packet data :
      #   - ID, id: Integer
      #   - REGISTER, secret: Integer, name: String
      #   - NEW_USER, id: Integer, name: String
      #   - LIST_USER_REQUEST, {}
      #   - LIST_USER_RESPONSE, response: {ID => Name} (Integer, String)
      #   - SEND_DATA_REQUEST, to: Array<Integer>, data: String
      #   - RECEIVED_DATA, from: Integer, data: String
      #   - FIND_USER_REQUEST, secret: Integer, name: String (respond a ID packet; id < 0 = not found)
      #   - FIND_USER_BY_NAME_REQUEST, name: String
      #   - FIND_USER_BY_NAME_RESPONSE, response: Array<Integer>
      class Packet < ::String
        # Packet containing an ID
        ID = 1
        # Packet containing a register request (Secret: Int, Name: String)
        REGISTER = 2
        # Packet containing the new user connection Info (ID: Int, Name: String)
        NEW_USER = 3
        # Packet containing the list user request
        LIST_USER_REQUEST = 4
        # Packet containing the list user response (Hash{ID=>Name})
        LIST_USER_RESPONSE = 5
        # Packet containing the send data request (Array<IDs>, Data)
        SEND_DATA_REQUEST = 6
        # Packet containing the data sent by an other user (ID: Int, Data)
        RECEIVED_DATA = 7
        # Packet containing a user disconnection (ID: Int)
        DISCONNECTION = 8
        # Packet containing a find user request (Secret: Int, Name: String)
        FIND_USER_REQUEST = 9
        # Packet containing a find user by name request (Name: String)
        FIND_USER_BY_NAME_REQUEST = 10
        # Packet containing the find user by name response (Array<ID>)
        FIND_USER_BY_NAME_RESPONSE = 11
        # Last Packet ID
        LAST_PACKET_ID = FIND_USER_BY_NAME_RESPONSE
        # Error during a packet encoding or decoding
        Error = Class.new(StandardError)

        # @return [Hash] the data of the packet
        attr_reader :data

        # Create a new packet
        # @param data [String, Hash] if data is a String, it's a packet to decode, otherwise it's a packet to encode
        def initialize(data)
          if data.is_a?(String)
            @data = {}
            raise Error, 'Received invalid packet' if data.bytesize != 5
            super(data)
          else
            super()
            initialize_hash(@data = data)
          end
        end

        # Return the size of the packet
        # @return [Integer]
        def size
          unpack('L').first
        end

        # Return the ID of the packet
        # @return [Integer]
        def id
          unpack('@4C').first
        end

        # Add data to the packet (also decode new data)
        # @param string [String]
        def <<(string)
          super
          decode_packet if @data.empty?
          self
        end

        private

        # Create a new packet from a Hash
        # @param data [Hash] hash info
        def initialize_hash(data)
          packet_id = data[:packet_id].to_i
          raise Error, 'Invalid packet id' unless packet_id.between?(ID, LAST_PACKET_ID)
          send(:"initialize_packet_#{packet_id}", data)
        end

        # Create a new ID packet
        # @param data [Hash] hash info
        def initialize_packet_1(data)
          self << [4, ID, data[:id].to_i].pack('LCl')
        end

        # Create a new REGISTER packet
        # @param data [Hash] hash info
        def initialize_packet_2(data)
          name = data[:name].to_s
          self << [4 + name.bytesize, REGISTER, data[:secret].to_i].pack('LCL') << name
        end

        # Create a new NEW_USER packet
        # @param data [Hash] hash info
        def initialize_packet_3(data)
          name = data[:name].to_s
          self << [4 + name.bytesize, NEW_USER, data[:id].to_i].pack('LCL') << name
        end

        # Create a new LIST_USER_REQUEST packet
        # @param _data [Hash] hash info
        def initialize_packet_4(_data)
          self << [0, LIST_USER_REQUEST].pack('LC')
        end

        # Create a new LIST_USER_RESPONSE packet
        # @param data [Hash] hash info
        def initialize_packet_5(data)
          response = data[:response]
          buffer = ''
          response.each do |id, name|
            buffer << [id, name.bytesize, name].pack('LSa*')
          end
          self << [2 + buffer.bytesize, LIST_USER_RESPONSE, response.size].pack('LCS') << buffer
        end

        # Create a new SEND_DATA_REQUEST packet
        # @param data [Hash] hash info
        def initialize_packet_6(data)
          to = data[:to]
          data = data[:data].to_s
          self << [2 + 4 * to.size + data.bytesize, SEND_DATA_REQUEST, to.size].pack('LCS')
          self << to.pack('L*') << data
        end

        # Create a new RECEIVED_DATA packet
        # @param data [Hash] hash info
        def initialize_packet_7(data)
          from = data[:from].to_i
          data = data[:data].to_s
          self << [4 + data.bytesize, RECEIVED_DATA, from].pack('LCL') << data
        end

        # Create a new DISCONNECTION packet
        # @param data [Hash] hash info
        def initialize_packet_8(data)
          self << [4, DISCONNECTION, data[:id].to_i].pack('LCL')
        end

        # Create a new FIND_USER_REQUEST packet
        # @param data [Hash] hash info
        def initialize_packet_9(data)
          name = data[:name].to_s
          self << [4 + name.bytesize, FIND_USER_REQUEST, data[:secret].to_i].pack('LCL') << name
        end

        # Create a new FIND_USER_BY_NAME_REQUEST packet
        # @param data [Hash] hash info
        def initialize_packet_10(data)
          name = data[:name].to_s
          self << [name.bytesize, FIND_USER_BY_NAME_REQUEST].pack('LC') << name
        end

        # Create a new FIND_USER_BY_NAME_RESPONSE packet
        # @param data [Hash] hash info
        def initialize_packet_11(data)
          response = data[:response]
          self << [2 + response.size * 4, FIND_USER_BY_NAME_RESPONSE, response.size].pack('LCS') << response.pack('L*')
        end

        # Decode the current packet
        def decode_packet
          packet_id = id
          raise Error, 'Invalid packet id' unless packet_id.between?(ID, LAST_PACKET_ID)
          send(:"decode_packet_#{packet_id}")
          @data[:packet_id] = packet_id
        end

        # Decode a ID packet
        def decode_packet_1
          @data[:id] = unpack('@5l').first
        end

        # Decode a REGISTER packet
        def decode_packet_2
          @data[:secret], @data[:name] = unpack('@5La*')
        end

        # Decode a NEW_USER packet
        def decode_packet_3
          @data[:id], @data[:name] = unpack('@5La*')
        end

        # Decode a LIST_USER_REQUEST packet
        def decode_packet_4; end

        # Decode a LIST_USER_RESPONSE packet
        def decode_packet_5
          num_entry = unpack('@5S').first
          current_index = 7
          @data[:response] = response = {}
          num_entry.times do
            id, name_size = unpack("@#{current_index}LS")
            response[id] = self[current_index += 6, name_size]
            current_index += name_size
          end
        end

        # Decode a SEND_DATA_REQUEST packet
        def decode_packet_6
          num_entry = unpack('@5S').first
          *@data[:to], @data[:data] = unpack("@7L#{num_entry}a*")
        end

        # Decode a RECEIVED_DATA packet
        def decode_packet_7
          @data[:from], @data[:data] = unpack('@5La*')
        end

        # Decode a DISCONNECTION packet
        def decode_packet_8
          @data[:id] = unpack('@5L').first
        end

        # Decode a FIND_USER_REQUEST packet
        def decode_packet_9
          @data[:secret], @data[:name] = unpack('@5La*')
        end

        # Decode a FIND_USER_BY_NAME_REQUEST packet
        def decode_packet_10
          @data[:name] = unpack('@5a*')
        end

        # Decode a FIND_USER_BY_NAME_RESPONSE packet
        def decode_packet_11
          num_entry = unpack('@5S').first
          @data[:response] = unpack("@7L#{num_entry}")
        end
      end
    end
  end
end
