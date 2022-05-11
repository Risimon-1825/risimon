module Battle
  module AI
    class MoveHeuristicBase
      class ReflectMoves < MoveHeuristicBase
        # Create a new Rest Heuristic
        def initialize
          super(true, true, true)
        end

        # Compute the heuristic
        # @param move [Battle::Move]
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler]
        # @param ai [Battle::AI::Base]
        # @return [Float]
        def compute(move, user, target, ai)
          return 0 if ai.scene.logic.bank_effects[user.bank].has?(move.db_symbol) || (move.db_symbol == :aurora_veil && !$env.hail?)
          return 0.80 if move.db_symbol == :light_screen && ai.scene.logic.foes_of(user).none? { |foe| foe.moveset.none?(&:special?) }
          return 0.80 if move.db_symbol == :reflect && ai.scene.logic.foes_of(user).none? { |foe| foe.moveset.none?(&:physical?) }

          return 0.90 + ai.scene.logic.move_damage_rng.rand(0..0.10)
        end
      end

      register(:s_reflect, ReflectMoves, 1)
    end
  end
end
