Object.class_eval do
  define_method(:void) { |*| }
  define_method(:void_array) { |*| [] }
end
require_relative 'EncapsulatedClient'

describe(PFM::OnlineHandler::EncapsulatedClient) do
  it('passes send_data arguments to the client') do
    client = double
    encapsulated_client = PFM::OnlineHandler::EncapsulatedClient.new(client)

    expect(client).to receive(:send_data).with('with_ids', 1, 2, 3).once
    expect(client).to receive(:send_data).with('without_ids').once

    encapsulated_client.send_data('with_ids', 1, 2, 3)
    encapsulated_client.send_data('without_ids')
  end

  it('passes list_user_by_name arguments to the client') do
    client = double
    encapsulated_client = PFM::OnlineHandler::EncapsulatedClient.new(client)
    block_input = proc {}

    expect(client).to receive(:list_user_by_name).with('name') do |&block|
      expect(block).to be(block_input)
    end.once

    encapsulated_client.list_user_by_name('name', &block_input)
  end
end
