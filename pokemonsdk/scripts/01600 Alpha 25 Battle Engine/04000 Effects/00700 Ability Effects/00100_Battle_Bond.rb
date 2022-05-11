module Battle
  module Effects
    class Ability
      class BattleBond < Ability
        # Function called after damages were applied and when target died (post_damage_death)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage_death(handler, hp, target, launcher, skill)
          @activate = true if @activate.nil?
          if launcher == @target
            return unless launcher && launcher.hp > 0
            return if @activate == false

            original_form = launcher.form
            launcher.form_calibrate(:battle)
            if launcher.form != original_form
              handler.scene.visual.show_ability(launcher)
              handler.scene.visual.show_switch_form_animation(launcher)
            end
          elsif target == @target
            target.form = 0
            @activate = false
          end
        end
      end
      register(:battle_bond, BattleBond)
    end
  end
end
