module Battle
  module Effects
    class Ability
      class HungerSwitch < Ability
        # Function called at the end of a turn
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_end_turn_event(logic, scene, battlers)
          return unless battlers.include?(@target)
          return if @target.dead?

          original_form = @target.form
          if @target.form == 0
            @target.form_calibrate(:battle)
          else
            @target.form_calibrate
          end
          unless @target.form == original_form
            @logic.scene.visual.show_switch_form_animation(@target)
            @logic.scene.visual.wait_for_animation
          end
        end

        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          who.form_calibrate if who == @target
        end

        # Function called after damages were applied and when target died (post_damage_death)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage_death(handler, hp, target, launcher, skill)
          return if target != @target

          target.form = 0
        end
      end
      register(:hunger_switch, HungerSwitch)
    end
  end
end
