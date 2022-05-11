module Battle
  class Move
    # Move changing speed order of Pokemon
    class TrickRoom < Move
      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        effect_klass = Effects::TrickRoom
        if logic.terrain_effects.each.any? { |effect| effect.class == effect_klass }
          logic.terrain_effects.each { |effect| effect&.kill if effect.class == effect_klass }
          return false
        end
        logic.terrain_effects.add(Effects::TrickRoom.new(@scene.logic))
        scene.display_message_and_wait(parse_text_with_pokemon(19, 860, user))
      end
    end

    Move.register(:s_trick_room, TrickRoom)
  end
end
