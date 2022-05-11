module Battle
  # Battle scene that shows in the console
  class ConsoleScene < Scene
    # Display a message
    # @param message [String] the message to display
    # @param start [Integer] the start choice index (1..nb_choice)
    # @param choices [Array<String>] the list of choice options
    # @return [Integer, nil] the choice result
    def display_message(message, start = 1, *choices)
      Graphics.window.update if defined?(Graphics) && Graphics.window
      cc 0x07
      puts message
      return nil if choices.empty?

      choices.each_with_index do |choice, index|
        puts "[#{index}]: #{choice}"
      end
      cc 0x03
      print "Answer [#{start - 1}]: "
      result = nil
      Thread.new { result = STDIN.gets.chomp }
      until result
        Graphics.window.update if defined?(Graphics) && Graphics.window
        sleep(0.01)
      end
      return start - 1 if result.empty?

      return result.to_i
    end

    private

    # Create a new visual
    # @return [Battle::Visual]
    def create_visual
      return Battle::ConsoleVisual.new(self)
    end

    # Return the message class used by this scene
    # @return [Class]
    def message_class
      return ConsoleVisual::MockedMessage
    end
  end
end
