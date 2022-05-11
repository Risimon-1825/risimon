module Battle
  class Move
    # Move that inflict Knock Off to the ennemy
    class KnockOff < BasicWithSuccessfulEffect
      # Get the real base power of the move (taking in account all parameter)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, target)
        return @logic.item_change_handler.can_lose_item?(target, user) ? super * 1.5 : super
      end

      # Method calculating the damages done by the actual move
      # @note : I used the 4th Gen formula : https://www.smogon.com/dp/articles/damage_formula
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def damages(user, target)
        dmg = super
        if dmg > 0 && @logic.item_change_handler.can_lose_item?(target, user)
          additionnal_variables = {
            PFM::Text::ITEM2[2] => target.item_name,
            PFM::Text::PKNICK[1] => target.given_name
          }
          @scene.display_message_and_wait(parse_text_with_pokemon(19, 1056, user, additionnal_variables))
          if target.from_party? && !target.effects.has?(:item_stolen)
            target.effects.add(Effects::ItemStolen.new(@logic, target))
          else
            @logic.item_change_handler.change_item(:none, true, target, user, self)
          end
        end
        return dmg
      end
    end

    Move.register(:s_knock_off, KnockOff)
  end
end
