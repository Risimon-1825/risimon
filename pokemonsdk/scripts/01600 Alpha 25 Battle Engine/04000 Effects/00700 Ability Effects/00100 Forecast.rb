module Battle
  module Effects
    class Ability
      class Forecast < Ability
        # Function called at the end of a turn
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_end_turn_event(logic, scene, battlers)
          return unless battlers.include?(@target)
          return if @target.dead?

          original_form = @target.form
          return unless @target.form_generation(-1) != original_form

          scene.visual.show_switch_form_animation(@target)
        end

        # Function called after the weather was changed (on_post_weather_change)
        # @param handler [Battle::Logic::WeatherChangeHandler]
        # @param weather_type [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
        # @param last_weather [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
        def on_post_weather_change(handler, weather_type, last_weather)
          original_form = @target.form
          return unless @target.form_generation(-1) != original_form

          handler.scene.visual.show_switch_form_animation(@target)
        end
      end
      register(:forecast, Forecast)
    end
  end
end
