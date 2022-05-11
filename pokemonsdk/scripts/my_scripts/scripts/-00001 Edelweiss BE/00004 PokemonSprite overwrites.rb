module BattleUI
  # Sprite of a Pokemon in the battle
  class PokemonSprite
    private

    # Get the base position of the Pokemon in 1v1
    # @return [Array(Integer, Integer)]
    def base_position_v1
      return 226, 116 if enemy?

      return 76, 172
    end

    # Get the base position of the Pokemon in 2v2+
    # @return [Array(Integer, Integer)]
    def base_position_v2
      return 202, 133 if enemy?

      return 58, 179
    end

    # Get the offset position of the Pokemon in 2v2+
    # @return [Array(Integer, Integer)]
    def offset_position_v2
      return 60, 10
    end
  end
end
