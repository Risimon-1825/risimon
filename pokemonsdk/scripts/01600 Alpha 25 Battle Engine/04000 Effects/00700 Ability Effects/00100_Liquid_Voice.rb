module Battle
  module Effects
    class Ability
      class LiquidVoice < Ability
        # Function called when we try to get the definitive type of a move
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler] expected target
        # @param move [Battle::Move]
        # @param type [Integer] current type of the move (potentially after effects)
        # @return [Integer, nil] new type of the move
        def on_move_type_change(user, target, move, type)
          return GameData::Types::WATER if move.sound_attack?

          return nil
        end
      end
      register(:liquid_voice, LiquidVoice)
    end
  end
end
