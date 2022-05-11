module Battle
  module Effects
    class LuckyChant < PositionTiedEffectBase
      # Create a new Lucky Chant effect
      # @param logic [Battle::Logic]
      # @param bank [Integer] bank where the effect acts
      def initialize(logic, bank)
        super(logic, bank, 0)
        @counter = 5
      end

      # Get the effect name
      # @return [Symbol]
      def name
        return :lucky_chant
      end

      def on_delete
        @logic.scene.display_message_and_wait(parse_text(18, message_id + bank.clamp(0, 1)))
      end

      private

      # ID of the message that is responsible for telling the end of the effect
      # @return [Integer]
      def message_id
        return 152
      end
    end
  end
end
