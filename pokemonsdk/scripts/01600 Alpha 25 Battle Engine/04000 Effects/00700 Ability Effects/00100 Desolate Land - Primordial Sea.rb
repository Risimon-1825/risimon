module Battle
  module Effects
    class Ability
      class DesolateLand < Ability
        # Liste des temps qui peuvent changer
        WEATHERS = %i[hardsun hardrain wind]
        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          if with == @target
            weather_handler = handler.logic.weather_change_handler
            return unless weather_handler.weather_appliable?(env)

            handler.scene.visual.show_ability(with)
            weather_handler.weather_change(env, nil)
            handler.scene.visual.show_rmxp_animation(with, anim)
          elsif who == @target
            handler.logic.weather_change_handler.weather_change(:none, 0)
            handler.scene.display_message_and_wait(parse_text_with_pokemon(18, msg, who))
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
              handler.scene.display_message_and_wait(parse_text_with_pokemon(18, temps, target))
            end
          end
          return unless typeskill(skill) && env?
          return unless launcher&.can_be_lowered_or_canceled?

          return handler.prevent_change do
            handler.scene.visual.show_ability(target)
            handler.scene.display_message_and_wait(parse_text_with_pokemon(18, prevent, target))
          end
        end

        # Function called when a weather_prevention is checked
        # @param handler [Battle::Logic::WeatherChangeHandler]
        # @param weather_type [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog, :hardsun, :hardrain
        # @param last_weather [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog, :hardsun, :hardrain
        # @return [:prevent, nil] :prevent if the status cannot be applied
        def on_weather_prevention(handler, weather_type, last_weather)
          return if WEATHERS.include?(weather_type)

          return handler.prevent_change do
            handler.scene.visual.show_ability(@target)
            handler.scene.display_message_and_wait(parse_text_with_pokemon(18, temps, target))
          end
        end

        private

        def env
          return :hardsun
        end

        def env!
          return :hardrain
        end

        # @param skill [Battle::Move, nil] Potential move used
        def typeskill(skill)
          return skill&.type_water?
        end

        def env?
          return $env.hardsun?
        end

        def anim
          return 492
        end

        def msg
          return 272
        end

        def prevent
          return 276
        end

        def temps
          return 278
        end
      end
      register(:desolate_land, DesolateLand)

      class PrimordialSea < DesolateLand
        private

        def env
          return :hardrain
        end

        def env!
          return :hardsun
        end

        # @param skill [Battle::Move, nil] Potential move used
        def typeskill(skill)
          return skill&.type_fire?
        end

        def env?
          return $env.hardrain?
        end

        def anim
          return 493
        end

        def msg
          return 270
        end

        def prevent
          return 275
        end

        def temps
          return 277
        end
      end
      register(:primordial_sea, PrimordialSea)
    end
  end
end
