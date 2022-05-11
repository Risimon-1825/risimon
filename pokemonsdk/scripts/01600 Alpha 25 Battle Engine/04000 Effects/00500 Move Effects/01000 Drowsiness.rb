module Battle
  module Effects
    # Drowsiness make the pokemon fall asleep after a certain amount of turns, applied by Yawn
    # @see https://bulbapedia.bulbagarden.net/wiki/Yawn_(move)
    class Drowsiness < PokemonTiedEffectBase
      # Create a new Pokemon tied effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      # @param counter [Integer] (default:2)
      def initialize(logic, pokemon, counter = 2)
        super(logic, pokemon)
        self.counter = counter
        @logic.scene.display_message_and_wait(parse_text_with_pokemon(19, 667, @pokemon))
      end

      # If the effect can proc
      # @return [Boolean]
      def triggered?
        return @counter == 1
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :drowsiness
      end

      # Function called at the end of a turn
      # @param logic [Battle::Logic] logic of the battle
      # @param scene [Battle::Scene] battle scene
      # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
      def on_end_turn_event(logic, scene, battlers)
        return if @pokemon.dead?
        return unless triggered?
        return kill if logic.terrain_effects.has?(:electric_terrain) && @pokemon.grounded?
        return kill if @pokemon.asleep?

        logic.status_change_handler.status_change_with_process(:sleep, @pokemon)
      end

      # Function called when a Pokemon has actually switched with another one
      # @param handler [Battle::Logic::SwitchHandler]
      # @param who [PFM::PokemonBattler] Pokemon that is switched out
      # @param with [PFM::PokemonBattler] Pokemon that is switched in
      def on_switch_event(handler, who, with)
        kill if who == @pokemon
      end
    end
  end
end
