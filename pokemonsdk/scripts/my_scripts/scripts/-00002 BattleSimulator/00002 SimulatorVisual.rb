module Battle
  # Visual that outputs in the console
  class SimulatorVisual < Visual
    # Create a new visual instance
    # @param scene [Scene] scene that hold the logic object
    # @param output [StringIO] string io object used to show stupp
    def initialize(scene, output)
      super(scene)
      @output = output
    end

    alias create_viewport void
    alias create_background void
    alias create_battlers void
    alias create_ability_bar void
    alias create_item_bar void
    alias create_info_bar void
    alias create_team_info void
    alias create_player_choice void
    alias create_skill_choice void
    alias create_battle_animation_handler void
    alias show_pre_transition void
    alias show_transition void
    alias hide_info_bars void
    alias show_info_bars void
    alias show_info_bar void
    alias hide_info_bar void
    alias refresh_info_bar void
    alias set_info_state void
    alias show_team_info void
    alias hide_team_info void
    alias take_snapshot void

    def wait_for_animation
      @animations.clear
      return nil
    end

    # Retrieve the sprite of a battler
    # @param bank [Integer] bank where the battler should be
    # @param position [Integer, Symbol] Position of the battler
    # @return [BattleUI::PokemonSprite, nil] the Sprite of the battler if it has been stored
    def battler_sprite(bank, position)
      @mocked_sprite ||= MockedBattlerSprite.new
    end

    # Method that shows the trainer choice
    # @param pokemon_index [Integer] Index of the Pokemon in the party
    # @return [Symbol, Array(Symbol, Hash), nil] :attack, :bag, :pokemon, :flee, :cancel, :try_next
    def show_player_choice(pokemon_index)
      raise 'This should never be called'
    end

    # Method that show the skill choice and store it inside an instance variable
    # @param pokemon_index [Integer] Index of the Pokemon in the party
    # @return [Boolean] if the player has choose a skill
    def show_skill_choice(pokemon_index)
      raise 'This should never be called'
    end

    # Method that show the target choice once the skill was choosen
    # @return [Array<PFM::PokemonBattler, Battle::Move, Integer(bank), Integer(position), Boolean(mega)>, nil]
    def show_target_choice
      raise 'This should never be called'
    end

    # Method that show the item choice
    # @return [PFM::ItemDescriptor::Wrapper, nil]
    def show_item_choice
      raise 'This should never be called'
    end

    # Method that show the pokemon choice
    # @param forced [Boolean]
    # @return [PFM::PokemonBattler, nil]
    def show_pokemon_choice(forced = false)
      raise 'This should never be called'
    end

    # Make the result of show_target_choice method
    # @param result [Array, :auto, :cancel]
    def stc_result(result = :auto)
      raise 'This should never be called'
    end

    # Show HP animations
    # @param targets [Array<PFM::PokemonBattler>]
    # @param hps [Array<Integer>]
    # @param effectiveness [Array<Integer, nil>]
    # @param messages [Proc] messages shown right before the post processing
    def show_hp_animations(targets, hps, effectiveness = [], &messages)
      targets.each_with_index do |target, index|
        if hps[index] < 0
          @output.puts "HP_DOWN: #{-hps[index]} => #{target}"
        elsif hps[index] > 0
          @output.puts "HP_UP: #{hps[index]} => #{target}"
        end
      end
      messages&.call
      show_kos(targets)
    end

    # Show KO animations
    # @param targets [Array<PFM::PokemonBattler>]
    def show_kos(targets)
      targets = targets.select(&:dead?)
      return if targets.empty?

      targets.each do |target|
        @output.puts "KO: #{target}"
      end
    end

    # Show the ability animation
    # @param target [PFM::PokemonBattler]
    # @param [Boolean] no_go_out Set if the out animation should be not played automatically
    def show_ability(target, no_go_out = false)
      @output.puts "ABILITY: #{target.ability_name} of #{target}"
    end
    alias hide_ability void

    # Show the item user animation
    # @param target [PFM::PokemonBattler]
    def show_item(target)
      @output.puts "ITEM: #{target.item_name} of #{target}"
    end
    alias show_switch_form_animation void

    alias show_move_animation void
    alias show_rmxp_animation void
    alias show_exp_distribution void
    alias show_catch_animation void

    class MockedBattlerSprite
      attr_accessor :pokemon
      alias go_in void
      alias go_out void
      alias visible void_true
      alias visible= void_true
      alias x void0
      alias x= void0
      alias y void0
      alias y= void0
      alias z void0
      alias z= void0
      alias ox void0
      alias ox= void0
      alias oy void0
      alias oy= void0
      alias zoom void0
      alias zoom= void0
      alias opacity void0
      alias opacity= void0
      alias width void0
      alias height void0
      alias done? void_true
      alias update void
      alias viewport void
    end

    class MockedMessage < MockedBattlerSprite
      attr_accessor :blocking, :wait_input, :position_overwrite, :windowskin_overwrite, :nameskin_overwrite, :line_number_overwrite, :width_overwrite,
                    :drawing_message, :auto_skip, :stay_visible, :input_number_window

      alias initialize void
    end
  end
end
