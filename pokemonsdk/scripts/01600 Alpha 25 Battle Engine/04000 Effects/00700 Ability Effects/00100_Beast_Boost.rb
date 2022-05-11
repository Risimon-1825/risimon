module Battle
  module Effects
    class Ability
      class BeastBoost < Ability
        # Function called after damages were applied and when target died (post_damage_death)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage_death(handler, hp, target, launcher, skill)
          return if launcher != @target || launcher == target
          return unless launcher && launcher.hp > 0

          stat = boosted_stat(launcher.spd, launcher.dfs, launcher.ats, launcher.dfe, launcher.atk)
          return if stat.nil?

          if handler.logic.stat_change_handler.stat_increasable?(stat, launcher)
            handler.scene.visual.show_ability(launcher)
            handler.logic.stat_change_handler.stat_change_with_process(stat, 1, launcher)
          end
        end

        private

        # @param spd [Integer] Return the current spd
        # @param dfs [Integer] Return the current dfs
        # @param ats [Integer] Return the current ats
        # @param dfe [Integer] Return the current dfe
        # @param atk [Integer] Return the current atk
        def boosted_stat(spd, dfs, ats, dfe, atk)
          stats = [
            [:spd, spd],
            [:dfs, dfs],
            [:ats, ats],
            [:dfe, dfe],
            [:atk, atk]
          ]
          return stats.max_by(&:last)&.first
        end
      end
      register(:beast_boost, BeastBoost)
    end
  end
end
