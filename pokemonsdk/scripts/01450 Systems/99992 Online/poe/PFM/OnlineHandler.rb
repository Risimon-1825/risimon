module PFM
  # Module responsive of handling online stuff in PSDK
  module OnlineHandler
    # @type [NuriGame::Online::Proxy::Client]
    @client = nil
    @mutex = Mutex.new
    @queue = SizedQueue.new(1)
    @mode = :none

    class << self
      # Get the ID of the player on the Proxy
      # @return [Integer]
      attr_reader :id
      # Get the current mode of the OnlineHandler
      # @return [Symbol] (see README.md)
      attr_reader :mode

      # Tell if the OnlineHandler is conncted
      # @return [Boolean]
      def connected?
        !@client.nil? && @client.connected?
      end

      # Tell if the OnlineHandler is locked in a mutex
      # @return [Boolean]
      def locked?
        @mutex.locked?
      end

      # Disconnect the OnlineHandler from the Proxy
      def disconnect
        return unless connected?

        @mode = :none
        @client.disconnect
        @client = nil
      end

      # Connect the OnlineHandler to the listed battles
      # @param driver [DriverBase]
      # @yieldparam success [Boolean] if the operation was successfull
      def connect_to_listed_battle(driver, &block)
        return block.call(false) if locked?

        connect_to_service(driver, :listed_battle, 'ListedBattle', &block)
      end

      private

      # Function that connects the OnlineHandler to a service of the proxy
      # @param driver [DriverBase]
      # @param mode [Symbol]
      # @param service_name [String, nil]
      # @yieldparam success [Boolean] if the operation was successfull
      def connect_to_service(driver, mode, service_name = nil, &block)
        Thread.new do
          reconnect_to_proxy do |connected, id|
            break block.call(false) unless connected

            @id = id
            @mode = mode
            bind_client(driver, service_name)
            block.call(true)
          end
        end
        @queue.pop
      end

      # Function that reconnects the client to the proxy (safely)
      # @yieldparam connected [Boolean] if the connection is successfull
      # @yieldparam id [Integer] current ID of the client
      def reconnect_to_proxy(&block)
        @queue.clear
        @mutex.synchronize do
          @queue.push(nil) # Should always be called before the block because queues blocks threads where pop is called
          disconnect
          @client = NuriGame::Online::Proxy::Client.new
          @client.connect(Configs.online_configs.server_ip, Configs.online_configs.server_port, &block)
        end
      rescue StandardError => e
        @queue.push(nil) if @queue.empty?
        log_error("Failed to connect... [#{e.class}]: #{e.message}")
        block.call(false, nil)
      end

      # Function that binds a client to a driver and also inform the proxy about name & secret
      # @param driver [DriverBase]
      # @param service_name [String, nil]
      def bind_client(driver, service_name = nil)
        final_name = compute_final_name(driver, service_name)
        driver.name = final_name
        driver.secret = final_name && secret
        driver.client = EncapsulatedClient.new(@client)
        @client.on_user_connect { |id, name| driver.on_user_connect(id, name) }
        @client.on_user_disconnect { |id| driver.on_user_disconnect(id) }
        @client.on_data_received { |from_id, data| driver.on_data_received(from_id, data) }
        @client.register(final_name, driver.secret) if final_name
      end

      # Function that computes the final name of the client based on the service name and driver info
      # @param driver [DriverBase]
      # @param service_name [String, nil]
      # @return [String, nil]
      def compute_final_name(driver, service_name)
        return nil unless service_name
        return "#{service_name}:#{driver.name_suffix}" if driver.respond_to?(:name_suffix)

        return service_name
      end

      # Function that computes the client secret
      # @return [String]
      def secret
        time = Time.new.utc.strftime('%Y-%m-%d %H:%M:%S.%3N')
        return Digest::SHA1.hexdigest(time) unless $trainer

        return Digest::SHA1.hexdigest("#{$trainer.name}\x00#{$trainer.id}\x00#{time}")
      end
    end
  end
end
