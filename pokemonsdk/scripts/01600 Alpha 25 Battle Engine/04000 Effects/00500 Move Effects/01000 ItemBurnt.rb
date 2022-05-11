module Battle
  module Effects
    # Implement the Item Burnt effect
    class ItemBurnt < PokemonTiedEffectBase
      # Get the name of the effect
      # @return [Symbol]
      def name
        return :item_burnt
      end
    end
  end
end
