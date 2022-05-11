module Battle
  module Effects
    class Item
      class RedCard < Item
        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if target != @target
          return unless skill && launcher != target && handler.logic.can_battler_be_replaced?(launcher)
          return if handler.logic.switch_request.any? { |request| request[:who] == launcher }

          handler.scene.visual.show_item(target)
          rand_pkmn = (@logic.alive_battlers_without_check(launcher.bank).select { |p| p if p.party_id == launcher.party_id && p.position == -1 }).compact
          @logic.switch_request << { who: launcher, with: rand_pkmn.sample } unless rand_pkmn.empty?
          target.item_holding = target.battle_item = 0
        end
      end
      register(:red_card, RedCard)
    end
  end
end
