module Battle
  class Scene
    class Message
      # Windowskin used by Edelweiss BE
      EDELWEISS_WINDOW_SKIN = 'm_7'
      # Battle Windowskin
      # @return [String]
      def current_windowskin
        @windowskin_overwrite || EDELWEISS_WINDOW_SKIN
      end

      # Return the default line number
      # @return [Integer]
      def default_line_number
        return 1
      end

      # Return the default vertical margin
      # @return [Integer]
      def default_vertical_margin
        return 20
      end

      def init_pause_coordinates
        self.pause_x = width - 15 - default_horizontal_margin
        self.pause_y = height - 20 # I made this change because of a bug, we can remove it later once the bug is fixed
      end
    end
  end
end
