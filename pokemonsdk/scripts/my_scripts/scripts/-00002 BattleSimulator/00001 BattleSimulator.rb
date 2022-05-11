module Battle
  # Battle scene that simulate turns
  class Simulator < Scene
    # Create a new Battle Scene
    # @param battle_info [Battle::Logic::BattleInfo] informations about the battle
    # @note This method create the banks, the AI, the pokemon battlers and the battle logic
    #       It should call the logic_init event
    def initialize(battle_info)
      @output = StringIO.new
      super(battle_info)
    end

    # Display a message
    # @param message [String] the message to display
    # @param start [Integer] the start choice index (1..nb_choice)
    # @param choices [Array<String>] the list of choice options
    # @return [Integer, nil] the choice result
    def display_message(message, start = 1, *choices)
      @output.puts "MESSAGE: #{message}"
    end

    private

    def remove_all_logs
      Kernel.module_eval do
        alias log_debug void
        alias log_data void
        alias log_info void
        alias log_error void
      end
    end

    def load_rng
      logic.load_rng(
        {
          move_damage_rng: 0,
          move_critical_rng: 0,
          move_accuracy_rng: 0,
          generic_rng: 0
        }
      )
    end

    def load_pokemon(user_db_symbol, target_db_symbol)
      (user = logic.battler(0, 0)).instance_variable_set(:@id, GameData::Pokemon[user_db_symbol].id)
      reset_pokemon(user)
      (target = logic.battler(1, 0)).instance_variable_set(:@id, GameData::Pokemon[target_db_symbol].id)
      reset_pokemon(target)
    end

    # @param pokemon [PFM::PokemonBattler]
    def reset_pokemon(pokemon)
      pokemon.cure
      pokemon.hp = pokemon.max_hp
      pokemon.effects.send(:initialize)
      pokemon.reset_states
      pokemon.instance_variable_set(:@ability, -1)
      pokemon.instance_variable_set(:@item_holding, -1)
      pokemon.move_history.clear
    end

    def time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    # Create a new visual
    # @return [Battle::Visual]
    def create_visual
      return Battle::SimulatorVisual.new(self, @output)
    end

    # Return the message class used by this scene
    # @return [Class]
    def message_class
      return SimulatorVisual::MockedMessage
    end
  end
end
