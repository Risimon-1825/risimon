module Battle
  class Move
    # Class managing Brick Break move
    class BrickBreak < BasicWithSuccessfulEffect
      private

      WALLS = %i[light_screen reflect aurora_veil]
      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        bank = actual_targets.map(&:bank).first
        @logic.bank_effects[bank].each do |effect|
          next unless WALLS.include?(effect.name)

          if effect.name == :reflect
            @scene.display_message_and_wait(parse_text(18, bank == 0 ? 132 : 133))
          elsif effect.name == :light_screen
            @scene.display_message_and_wait(parse_text(18, bank == 0 ? 136 : 137))
          else
            @scene.display_message_and_wait(parse_text(18, bank == 0 ? 140 : 141))
          end
          log_info("PSDK Brick Break: #{effect.name} effect removed.")
          effect.kill
        end
      end
    end
    Move.register(:s_brick_break, BrickBreak)
  end
end
