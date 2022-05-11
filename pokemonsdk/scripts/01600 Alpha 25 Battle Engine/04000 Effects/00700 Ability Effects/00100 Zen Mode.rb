module Battle
  module Effects
    class Ability
      class ZenMode < Ability
        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          who.form_calibrate if who == @target && who != with
          return if with != @target

          original_form = with.form
          with.form_calibrate(:battle)
          if with.form != original_form
            handler.scene.visual.show_ability(with)
            handler.scene.visual.show_switch_form_animation(with)
            handler.scene.display_message_and_wait(parse_text(18, with.form.odd? ? transform : back))
          end
        end

        # Function called at the end of a turn
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_end_turn_event(logic, scene, battlers)
          return unless battlers.include?(@target)
          return if @target.dead?

          original_form = @target.form
          @target.form_calibrate(:battle)
          return if @target.form == original_form

          scene.visual.show_ability(@target)
          scene.visual.show_switch_form_animation(@target)
          scene.display_message_and_wait(parse_text(18, @target.form.odd? ? transform : back))
        end

        private

        def transform
          return 191
        end

        def back
          return 192
        end
      end
      register(:zen_mode, ZenMode)

      class Schooling < ZenMode
        private

        def transform
          return 288
        end

        def back
          return 289
        end
      end
      register(:schooling, Schooling)

      class PowerConstruct < ZenMode
        private

        def transform
          return 292
        end

        def back
          return 293
        end
      end
      register(:power_construct, PowerConstruct)

      class ShieldsDown < ZenMode
        private

        # Function called when a status_prevention is checked
        # @param handler [Battle::Logic::StatusChangeHandler]
        # @param status [Symbol] :poison, :toxic, :confusion, :sleep, :freeze, :paralysis, :burn, :flinch, :cure
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, nil] :prevent if the status cannot be applied
        def on_status_prevention(handler, status, target, launcher, skill)
          return if target != @target
          return if @target.form != 0
          return unless launcher&.can_be_lowered_or_canceled?

          return handler.prevent_change do
            handler.scene.visual.show_ability(target)
          end
        end

        def transform
          return 290
        end

        def back
          return 291
        end
      end
      register(:shields_down, ShieldsDown)
    end
  end
end
