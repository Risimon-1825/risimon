module Battle
  module AI
    class MoveHeuristicBase
      class CuringMove < MoveHeuristicBase
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
          return 0 if target.effects.has?(:heal_block)
          return 0 if target.has_ability?(:soundproof)
          return 0 if target.dead? || target.status == 0

          return 0.75 + ai.scene.logic.move_damage_rng.rand(0..0.25)
        end
      end

      register(:s_heal_bell, CuringMove, 1)
    end
  end
end
