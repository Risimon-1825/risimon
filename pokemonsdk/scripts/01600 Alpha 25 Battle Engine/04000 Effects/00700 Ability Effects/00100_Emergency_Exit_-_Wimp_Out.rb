module Battle
  module Effects
    class Ability
      class EmergencyExit < Ability
        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if target != @target
          return if target.hp_rate > 0.5
          return unless skill && launcher != target && handler.logic.can_battler_be_replaced?(target)
          return if handler.logic.switch_request.any? { |request| request[:who] == target }

          handler.scene.visual.show_ability(target)
          if $game_temp.trainer_battle
            handler.logic.switch_request << { who: target }
          else
            @battler_s = handler.scene.visual.battler_sprite(target.bank, target.position)
            @battler_s.flee_animation
            @logic.scene.visual.wait_for_animation
            handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 767, target))
            @logic.battle_result = 1
          end
        end
      end
      register(:emergency_exit, EmergencyExit)
      register(:wimp_out, EmergencyExit)
    end
  end
end
