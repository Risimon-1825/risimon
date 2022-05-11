module Battle
  module Effects
    # Implement the Item Stolen effect
    class ItemStolen < PokemonTiedEffectBase
      # Function called when a post_item_change is checked
      # @param handler [Battle::Logic::ItemChangeHandler]
      # @param db_symbol [Symbol] Symbol ID of the item
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      def on_post_item_change(handler, db_symbol, target, launcher, skill)
        return unless target != launcher
        return if %i[none __undef__].include?(db_symbol)
        return unless db_symbol == launcher.battle_item_db_symbol

        kill
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :item_stolen
      end
    end
  end
end
