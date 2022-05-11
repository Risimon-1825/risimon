module Battle
  module Effects
    class Ability
      class PerishBody < Ability
        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if target != @target || launcher == target
          return unless skill&.direct?
          return if target.effects.has?(:perish_song) || launcher.effects.has?(:perish_song)

          target.effects.add(effect(target))
          handler.scene.visual.show_ability(target)
          @logic.scene.display_message_and_wait(parse_text(18, 125))
          launcher.effects.add(effect(launcher))
        end

        # Return the effect of the ability
        # @param target [PFM::PokemonBattler] target that will be affected by the effect
        # @return [Effects::EffectBase]
        def effect(target)
          Effects::PerishSong.new(@logic, target, 4)
        end
      end
      register(:perish_body, PerishBody)
    end
  end
end
