Object.class_eval do
  define_method(:void) { |*| }
  define_method(:void_array) { |*| [] }
end
require_relative 'EncapsulatedClient'
require_relative 'OnlineHandler'
require_relative 'Drivers/Base'
require 'digest'

PFM::OnlineHandler.module_eval do
  client = Class.new
  proxy = Module.new
  proxy.const_set(:Client, client)
  online = Module.new
  online.const_set(:Proxy, proxy)
  ng = Module.new
  ng.const_set(:Online, online)
  const_set(:NuriGame, ng)
  data = Struct.new(:server_ip, :server_port).new('server_ip', 'server_port')
  const_set(:Configs, Struct.new(:online_configs).new(data))
end

describe(PFM::OnlineHandler) do
  it('is disconnected, unlocked and have no mode in initial state') do
    expect(PFM::OnlineHandler.connected?).to be(false)
    expect(PFM::OnlineHandler.locked?).to be(false)
    expect(PFM::OnlineHandler.mode).to be(:none)
  end

  it('Really give locked state based on a Mutex') do
    # @type [Mutex]
    mutex = PFM::OnlineHandler.instance_variable_get(:@mutex)

    expect(PFM::OnlineHandler.locked?).to be(false)
    mutex.lock
    expect(PFM::OnlineHandler.locked?).to be(true)
    mutex.unlock
  end

  it('Really check connected state over the client') do
    client = double
    PFM::OnlineHandler.instance_variable_set(:@client, client)

    expect(client).to receive(:connected?).and_return(true).once
    expect(client).to receive(:connected?).and_return(false).once
    expect(PFM::OnlineHandler.connected?).to be(true)
    expect(PFM::OnlineHandler.connected?).to be(false)
    PFM::OnlineHandler.instance_variable_set(:@client, nil)
  end

  describe(:connect_to_listed_battle) do
    it('calls connect_to_service when handler is unlocked') do
      fake_driver = PFM::OnlineHandler::DriverBase.new
      block_input = proc {}

      expect(PFM::OnlineHandler).to receive(:connect_to_service).with(fake_driver, :listed_battle, 'ListedBattle') do |&block|
        expect(block).to be(block_input)
      end.once

      PFM::OnlineHandler.connect_to_listed_battle(fake_driver, &block_input)
    end

    it('immediately send false to the block parameter when handler locked') do
      # @type [Mutex]
      mutex = PFM::OnlineHandler.instance_variable_get(:@mutex)
      mutex.lock

      expect(PFM::OnlineHandler).not_to receive(:connect_to_service)
      PFM::OnlineHandler.connect_to_listed_battle(nil) do |success|
        expect(success).to be(false)
      end

      mutex.unlock
    end
  end

  describe(:bind_client) do
    before(:each) do
      client = double
      PFM::OnlineHandler.instance_variable_set(:@client, client)
    end

    it('binds the client to the driver as expected when service_name is nil') do
      fake_driver = PFM::OnlineHandler::DriverBase.new
      client = PFM::OnlineHandler.instance_variable_get(:@client)

      expect(client).to receive(:on_user_connect).with(no_args) { |&block| block.call('id', 'name') }
      expect(client).to receive(:on_user_disconnect).with(no_args) { |&block| block.call('id') }
      expect(client).to receive(:on_data_received).with(no_args) { |&block| block.call('from_id', 'data') }
      expect(client).not_to receive(:register)
      expect(fake_driver).to receive(:name=).with(nil)
      expect(fake_driver).to receive(:secret=).with(nil)
      expect(fake_driver).to receive(:client=).with(kind_of(PFM::OnlineHandler::EncapsulatedClient))
      expect(fake_driver).to receive(:on_user_connect).with('id', 'name')
      expect(fake_driver).to receive(:on_user_disconnect).with('id')
      expect(fake_driver).to receive(:on_data_received).with('from_id', 'data')

      PFM::OnlineHandler.send(:bind_client, fake_driver)
    end

    it('binds the client to the driver as expected') do
      fake_driver = PFM::OnlineHandler::DriverBase.new
      client = PFM::OnlineHandler.instance_variable_get(:@client)

      expect(client).to receive(:on_user_connect).with(no_args) { |&block| block.call('id', 'name') }
      expect(client).to receive(:on_user_disconnect).with(no_args) { |&block| block.call('id') }
      expect(client).to receive(:on_data_received).with(no_args) { |&block| block.call('from_id', 'data') }
      expect(client).to receive(:register).with('ServiceName', kind_of(String))
      expect(fake_driver).to receive(:name=).with('ServiceName').and_call_original
      expect(fake_driver).to receive(:secret=).with(kind_of(String)).and_call_original
      expect(fake_driver).to receive(:client=).with(kind_of(PFM::OnlineHandler::EncapsulatedClient)).and_call_original
      expect(fake_driver).to receive(:on_user_connect).with('id', 'name')
      expect(fake_driver).to receive(:on_user_disconnect).with('id')
      expect(fake_driver).to receive(:on_data_received).with('from_id', 'data')

      PFM::OnlineHandler.send(:bind_client, fake_driver, 'ServiceName')
    end

    it('binds the client to the driver as expected when driver has name_suffix') do
      fake_driver = PFM::OnlineHandler::DriverBase.new
      def fake_driver.name_suffix
        'suffix'
      end
      client = PFM::OnlineHandler.instance_variable_get(:@client)

      expect(client).to receive(:on_user_connect).with(no_args) { |&block| block.call('id', 'name') }
      expect(client).to receive(:on_user_disconnect).with(no_args) { |&block| block.call('id') }
      expect(client).to receive(:on_data_received).with(no_args) { |&block| block.call('from_id', 'data') }
      expect(client).to receive(:register).with('ServiceName:suffix', kind_of(String))
      expect(fake_driver).to receive(:name=).with('ServiceName:suffix').and_call_original
      expect(fake_driver).to receive(:secret=).with(kind_of(String)).and_call_original
      expect(fake_driver).to receive(:client=).with(kind_of(PFM::OnlineHandler::EncapsulatedClient)).and_call_original
      expect(fake_driver).to receive(:on_user_connect).with('id', 'name')
      expect(fake_driver).to receive(:on_user_disconnect).with('id')
      expect(fake_driver).to receive(:on_data_received).with('from_id', 'data')

      PFM::OnlineHandler.send(:bind_client, fake_driver, 'ServiceName')
    end

    after(:each) do
      PFM::OnlineHandler.instance_variable_set(:@client, nil)
    end
  end

  describe(:reconnect_to_proxy) do
    it('wakes the thread up and disconnect before reconnecting to proxy in a mutex') do
      block_param = proc {}
      client = PFM::OnlineHandler::NuriGame::Online::Proxy::Client

      expect(PFM::OnlineHandler.instance_variable_get(:@mutex)).to receive(:synchronize) { |&block| block.call }.once.ordered
      expect(PFM::OnlineHandler.instance_variable_get(:@queue)).to receive(:push).with(nil).once.ordered
      expect(PFM::OnlineHandler).to receive(:disconnect).once.ordered
      expect_any_instance_of(client).to receive(:connect).with('server_ip', 'server_port') do |&block|
        expect(block).to eq(block_param)
      end

      PFM::OnlineHandler.send(:reconnect_to_proxy, &block_param)
    end

    it('calls the block with false in case of error') do
      block_param = proc {}

      expect(PFM::OnlineHandler).to receive(:log_error).with('Failed to connect... [RuntimeError]: some error').once
      expect(PFM::OnlineHandler.instance_variable_get(:@mutex)).to receive(:synchronize) { |&block| block.call }.once
      expect(PFM::OnlineHandler.instance_variable_get(:@queue)).to receive(:push).with(nil).once.ordered
      expect(PFM::OnlineHandler.instance_variable_get(:@queue)).to receive(:empty?).and_return(false)
      expect(PFM::OnlineHandler).to receive(:disconnect) { raise 'some error' }.once
      expect(block_param).to receive(:call).with(false, nil).once

      PFM::OnlineHandler.send(:reconnect_to_proxy, &block_param)
    end
  end

  describe(:connect_to_service) do
    before(:each) do
      PFM::OnlineHandler.instance_variable_set(:@id, nil)
      PFM::OnlineHandler.instance_variable_set(:@mode, :none)
      PFM::OnlineHandler.instance_variable_get(:@queue).clear
    end

    it('calls the block with false if reconnect fails') do
      block_input = proc {}

      expect(PFM::OnlineHandler.locked?).to be(false)
      expect(PFM::OnlineHandler).to receive(:reconnect_to_proxy) do |&block|
        PFM::OnlineHandler.instance_variable_get(:@queue).push(nil)
        block.call(false, nil)
      end

      expect(block_input).to receive(:call).with(false).once
      Thread.new { PFM::OnlineHandler.send(:connect_to_service, nil, :mode, &block_input) }.join

      expect(PFM::OnlineHandler.instance_variable_get(:@id)).to be(nil)
      expect(PFM::OnlineHandler.instance_variable_get(:@mode)).to be(:none)
    end

    it('calls the block with true if reconnect succeed') do
      block_input = proc {}

      expect(PFM::OnlineHandler.locked?).to be(false)
      expect(PFM::OnlineHandler).to receive(:reconnect_to_proxy) do |&block|
        block.call(true, 'some_id')
        PFM::OnlineHandler.instance_variable_get(:@queue).push(nil)
      end
      expect(PFM::OnlineHandler).to receive(:bind_client).with('driver', 'service name').ordered
      expect(block_input).to receive(:call).with(true).once

      Thread.new { PFM::OnlineHandler.send(:connect_to_service, 'driver', :mode, 'service name', &block_input) }.join

      expect(PFM::OnlineHandler.instance_variable_get(:@id)).to eq('some_id')
      expect(PFM::OnlineHandler.instance_variable_get(:@mode)).to be(:mode)
    end

    it('does not lock forever') do
      client = PFM::OnlineHandler::NuriGame::Online::Proxy::Client
      block_input = proc {}

      expect(PFM::OnlineHandler.locked?).to be(false)
      expect(PFM::OnlineHandler).to receive(:disconnect) { sleep(0.2) }.ordered
      expect_any_instance_of(client).to receive(:connect) { |&block| block.call(true, 'some_id') }
      expect(PFM::OnlineHandler).to receive(:bind_client).ordered
      expect(block_input).to receive(:call).with(true)

      thread = Thread.new { PFM::OnlineHandler.send(:connect_to_service, nil, :mode, &block_input) }
      10.times do
        break unless thread.status

        sleep(0.01)
      end

      expect(thread.status).to be(false)
      expect(PFM::OnlineHandler.locked?).to be(true)
      sleep(0.3)
      expect(PFM::OnlineHandler.locked?).to be(false)
    end
  end
end
