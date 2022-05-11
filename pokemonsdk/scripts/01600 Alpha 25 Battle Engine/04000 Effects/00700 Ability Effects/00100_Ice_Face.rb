module Battle
  module Effects
    class Ability
      class IceFace < Ability
        # Function called when a damage_prevention is checked
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, Integer, nil] :prevent if the damage cannot be applied, Integer if the hp variable should be updated
        def on_damage_prevention(handler, hp, target, launcher, skill)
          return if target != @target || target.effects.has?(:heal_block) || !skill&.physical?
          return unless launcher&.can_be_lowered_or_canceled?

          @original_form = @target.form
          @target.form_calibrate(:battle)
          @hail = $env.hail?

          if @target.form != @original_form
            return handler.prevent_change do
              handler.scene.visual.show_ability(target)
              handler.scene.visual.show_switch_form_animation(target)
            end
          end
        end

        # Function called when a weather_prevention is checked
        # @param handler [Battle::Logic::WeatherChangeHandler]
        # @param weather_type [Symbol] - :none, :rain, :sunny, :sandstorm, :hail, :fog
        # @param last_weather [Symbol] - :none, :rain, :sunny, :sandstorm, :hail, :fog

        def on_weather_prevention(handler, weather_type, last_weather)
          return if target != @target

          return unless weather_type == :hail && @hail == false

          @original_form = @target.form
          @target.form_calibrate
          @hail = true
          if @target.form != @original_form
            handler.prevent_change
            handler.scene.visual.show_ability(target)
            handler.scene.visual.show_switch_form_animation(target)
            super
          end
        end

        # Function called at the end of a turn
        # logic [Battle::Logic] - logic of the battle
        # scene [Battle::Scene] - battle scene
        # battlers [Array<PFM::PokemonBattler>] - all alive battlers
        def on_end_turn_event(logic, scene, battlers)
          @hail = $env.hail?
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
      register(:ice_face, IceFace)
    end
  end
end
