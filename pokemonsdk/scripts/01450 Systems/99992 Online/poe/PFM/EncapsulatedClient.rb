module PFM
  module OnlineHandler
    # Class responsive of encapsulating the Proxy client so the drivers cannot do unexpected things
    class EncapsulatedClient
      # Create a new EncapsulatedClient
      # @param real_client [NuriGame::Online::Proxy::Client]
      def initialize(real_client)
        @client = real_client
      end

      # Send data to other clients
      # @example client.send_data('data', his_id)
      # @param data [String] the data
      # @param ids [Array<Integer>] list of ids that should receive the data
      def send_data(data, *ids)
        @client.send_data(data, *ids)
      end

      # Try to list all the user of the server that match a specific name
      # @example client.list_user_by_name(name) { |success, id_list| do_somethind_with_id_list }
      # @param name [String]
      # @yieldparam success [Boolean] if the operation was successfull
      # @yieldparam id_list [Array<Integer>] list of user ids
      def list_user_by_name(name, &block)
        @client.list_user_by_name(name, &block)
      end

      # Ensure no dirty hack can be used over this Encapsulation
      alias instance_variable_get void
      alias instance_variable_set void
      alias instance_variables void_array
    end
  end
end
