module Battle
  module AI
    class MoveHeuristicBase
      class HealingMoves < MoveHeuristicBase
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
          return 0 if target.bank != user.bank
          return 0 if move.db_symbol == :heal_pulse && target.effects.has?(:substitute)
          return 0 if healing_sacrifice_clause(move, user, target, ai)

          return (1 - target.hp_rate) * 2
        end

        # Test if sacrifice move should not be used
        # @param move [Battle::Move]
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler]
        # @param ai [Battle::AI::Base]
        # @return [Float]
        def healing_sacrifice_clause(move, user, target, ai)
          return move.is_a?(Move::HealingSacrifice) &&
                 ai.scene.logic.can_battler_be_replaced?(target) &&
                 ai.scene.logic.allies_of(target).none? { |pokemon| pokemon.hp_rate <= 0.75 && pokemon.party_id == target.party_id }
        end
      end

      register(:s_heal, HealingMoves, 1)
      register(:s_heal_weather, HealingMoves, 1)
      register(:s_healing_wish, HealingMoves, 1)
      register(:s_lunar_dance, HealingMoves, 1)
    end
  end
end
