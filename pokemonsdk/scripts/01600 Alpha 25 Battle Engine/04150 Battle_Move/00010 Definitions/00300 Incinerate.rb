module Battle
  class Move
    # Class managing the Incinerate move
    class Incinerate < BasicWithSuccessfulEffect
      DESTROYABLE_ITEMS = %i[
        fire_gem water_gem electric_gem grass_gem ice_gem fighting_gem poison_gem ground_gem flying_gem
        psychic_gem bug_gem rock_gem ghost_gem dragon_gem dark_gem steel_gem normal_gem fairy_gem
      ]

      # Method calculating the damages done by the actual move
      # @note : I used the 4th Gen formula : https://www.smogon.com/dp/articles/damage_formula
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def damages(user, target)
        dmg = super
        if dmg > 0 && @logic.item_change_handler.can_lose_item?(target, user)
          if DESTROYABLE_ITEMS.include?(target.battle_item_db_symbol)
            @logic.item_change_handler.change_item(:none, true, target, user, self)
          elsif target.hold_berry?(target.battle_item_db_symbol) && !target.effects.has?(:item_burnt)
            @scene.display_message_and_wait(parse_text_with_pokemon(19, 1114, target, PFM::Text::ITEM2[1] => target.item_name))
            target.effects.add(Effects::ItemBurnt.new(@logic, target))
          end
        end

        return dmg
      end
    end
    Move.register(:s_incinerate, Incinerate)
  end
end
