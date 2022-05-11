# frozen_string_literal: true

module Studio
  # Class responsive of handling communication between Studio & PSDK
  class Handler
    def initialize
      @in = STDIN
      @select_in = [@in]
      @out = STDOUT
      @out.sync = true
      @err = STDERR
      @err.sync = true
    end

    # Start the Studio Handler processing
    def start
      @out.puts({ ready: true, message: 'PSDK is ready!' }.to_json)
      until @in.closed?
        result = read_input
        if result
          process(result)
        else
          break
        end
      end
    end

    private

    # Read the input
    # @return [String, false]
    def read_input
      IO.select(@select_in)
      return false if @in.closed?

      return @in.gets
    end

    # Process the input
    # @param input [String]
    def process(input)
      data = JSON.parse(input)
      if data['action']
        process_action(data['action'], data['payload'])
      else
        puts data.to_s
      end
    rescue StandardError => e
      @err.puts({ type: :input_error, message: 'Failed to parse input', klass: e.class, error_message: e.message }.to_json)
    end

    # Process a specific action
    # @param action [String]
    # @param payload [Array, Hash, nil]
    def process_action(action, payload)
      case action
      when 'exit'
        Process.exit!(0)
      when 'importProjectToStudio'
        GameData.load
        @out.puts({ progress: 'dataLoaded', message: 'Data loaded!' }.to_json)
        ScriptLoader.load_tool('PSDKEditor')
        @out.puts({ progress: 'converterLoaded', message: 'Studio converter loaded!' }.to_json)
        PSDKEditor.convert
        @out.puts({ done: true, message: 'Conversion to Studio done!' }.to_json)
      when 'psdkConfig'
        @out.puts({ done: true, psdkConfig: { gameTitle: PSDK_CONFIG.game_title } }.to_json)
      end
    end
  end
end
