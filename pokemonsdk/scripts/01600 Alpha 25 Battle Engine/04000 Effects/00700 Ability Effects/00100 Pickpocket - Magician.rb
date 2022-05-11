module Battle
  module Effects
    class Ability
      class Pickpocket < Ability
        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if target != @target || launcher == target || !%i[none __undef__].include?(target.item_db_symbol)
          return unless skill&.direct? && launcher && launcher.hp > 0
          return unless handler.logic.item_change_handler.can_lose_item?(launcher, target)

          handler.scene.visual.show_ability(target)
          handler.logic.item_change_handler.change_item(launcher.item_db_symbol, !$game_temp.trainer_battle, target)
          text = parse_text_with_pokemon(19, 460, launcher, PFM::Text::PKNICK[0] => launcher.given_name, PFM::Text::ITEM2[1] => target.item_name)
          handler.scene.display_message_and_wait(text)
          target.effects.get(:item_stolen).kill if target.effects.has?(:item_stolen)
          if launcher.from_party?
            launcher.effects.add(Effects::ItemStolen.new(@logic, launcher))
          else
            handler.logic.item_change_handler.change_item(:none, true, launcher)
          end
        end
      end
      register(:pickpocket, Pickpocket)

      class Magician < Ability
        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if launcher != @target || launcher == target || !%i[none __undef__].include?(launcher.item_db_symbol)
          return unless skill&.direct? && launcher && launcher.hp > 0
          return unless handler.logic.item_change_handler.can_lose_item?(target, launcher)

          handler.scene.visual.show_ability(launcher)
          handler.logic.item_change_handler.change_item(target.item_db_symbol, !$game_temp.trainer_battle, launcher)
          text = parse_text_with_pokemon(19, 1063, launcher, '[VAR 1400(0002)]' => nil.to_s,
                                                             '[VAR ITEM2(0002)]' => target.item_name,
                                                             '[VAR PKNICK(0001)]' => target.given_name)
          handler.scene.display_message_and_wait(text)
          launcher.effects.get(:item_stolen).kill if launcher.effects.has?(:item_stolen)
          if target.from_party?
            target.effects.add(Effects::ItemStolen.new(@logic, target))
          else
            handler.logic.item_change_handler.change_item(:none, true, target)
          end
        end
      end
      register(:magician, Magician)
    end
  end
end
