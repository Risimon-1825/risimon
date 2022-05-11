module PFM
  module OnlineHandler
    # Base of all Online Drivers.
    # This class helps to build a valid Online Driver for your game by implementing some abstract methods
    class DriverBase
      # Client connected to the Proxy so the driver can operate properly
      # @return [OnlineHandler::EncapsulatedClient, nil]
      attr_accessor :client

      # Name of the client in the Proxy (if specified)
      # @return [String, nil]
      attr_accessor :name

      # Secret of the client in the Proxy (if specified)
      # @return [String, nil]
      attr_accessor :secret

      # !@method name_suffix
      #   Get the name suffix of this driver instance (not defined by default!)
      #   @return [String]

      # Method called by OnlineHandler when user connected on the Proxy
      # @param id [Integer] ID of the user
      # @param name [String] name of the user
      def on_user_connect(id, name)
        return nil
      end

      # Method called by OnlineHandler when data was received from another user of the proxy
      # @param from_id [Integer] ID of the user who sent the data
      # @param data [String] data received
      def on_data_received(from_id, data)
        return nil
      end

      # Method called by OnlineHandler when user disconnected from the proxy (to update listing mainly)
      # @param id [Integer] ID of the client who disconnected
      def on_user_disconnect(id)
        return nil
      end
    end
  end
end
