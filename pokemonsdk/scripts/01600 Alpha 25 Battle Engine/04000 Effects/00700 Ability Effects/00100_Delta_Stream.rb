module Battle
  module Effects
    class Ability
      class DeltaStream < Ability
        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          if with == @target
            weather_handler = handler.logic.weather_change_handler
            return unless weather_handler.weather_appliable?(:wind)

            handler.scene.visual.show_ability(with)
            weather_handler.weather_change(:wind, nil)
            handler.scene.visual.show_rmxp_animation(with, 566)
          else
            handler.logic.weather_change_handler.weather_change(:none, 0)
            handler.scene.display_message_and_wait(parse_text_with_pokemon(18, 274, who))
          end
        end

        # Function called when a damage_prevention is checked
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, Integer, nil] :prevent if the damage cannot be applied, Integer if the hp variable should be updated
        def on_damage_prevention(handler, hp, target, launcher, skill)
          return if target != @target

          if %i[rain_dance sunny_day hail sandstorm].include?(skill&.db_symbol)
            return handler.prevent_change do
              handler.scene.visual.show_ability(target)
              handler.scene.display_message_and_wait(parse_text_with_pokemon(18, 280, target))
            end
          end
        end

        # Function called when a weather_prevention is checked
        # @param handler [Battle::Logic::WeatherChangeHandler]
        # @param weather_type [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
        # @param last_weather [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
        # @return [:prevent, nil] :prevent if the status cannot be applied
        def on_weather_prevention(handler, weather_type, last_weather)
          return if weather_type == :wind

          return handler.prevent_change do
            handler.scene.visual.show_ability(@target)
            handler.scene.display_message_and_wait(parse_text_with_pokemon(18, 280, target))
          end
        end
      end
      register(:delta_stream, DeltaStream)
    end
  end
end
