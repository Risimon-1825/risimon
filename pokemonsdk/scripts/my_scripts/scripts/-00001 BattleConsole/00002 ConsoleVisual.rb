module Battle
  # Visual that outputs in the console
  class ConsoleVisual < Visual
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
      if (pokemon = @scene.logic.battler(0, pokemon_index)).effects.has?(&:force_next_move?)
        # @type [Effects::ForceNextMove]
        effect = pokemon.effects.get(&:force_next_move?)
        return :action, effect.make_action
      end

      choice = @scene.display_message("What will #{pokemon.given_name}do?", 1, 'Attack', 'Bag', 'Pokemon', 'Flee')
      return :attack if choice == 0
      return :bag if choice == 1
      return :pokemon if choice == 2

      return :flee
    end

    # Method that show the skill choice and store it inside an instance variable
    # @param pokemon_index [Integer] Index of the Pokemon in the party
    # @return [Boolean] if the player has choose a skill
    def show_skill_choice(pokemon_index)
      @pokemon_choice = pokemon = @scene.logic.battler(0, pokemon_index)
      moves = pokemon.moveset.map do |move|
        next "Disabled: #{move.name}" if move.disable_reason(pokemon)
        next "NoPP: #{move.name}" if move.pp <= 0

        move.name
      end << 'Cancel'
      choosen = false
      until choosen
        choice = @scene.display_message("Which move to use with #{pokemon.given_name}?", 1, *moves)
        @move_choice = pokemon.moveset[choice]
        next choosen = true unless @move_choice
        next @move_choice.disable_reason(pokemon).call if @move_choice.disable_reason(pokemon)
        next if @move_choice.pp <= 0

        choosen = true
      end
      return !@move_choice.nil?
    end

    # Method that show the target choice once the skill was choosen
    # @return [Array<PFM::PokemonBattler, Battle::Move, Integer(bank), Integer(position), Boolean(mega)>, nil]
    def show_target_choice
      return stc_result if stc_cannot_choose_target?

      targets = @move_choice.battler_targets(@pokemon_choice, @scene.logic)
      targets_choice = targets.map(&:to_s) << 'Cancel'
      choice = @scene.display_message("Which target to aim with #{@move_choice.name} from #{@pokemon.given_name}?", 1, *targets_choice)

      return stc_result(:cancel) unless targets[choice]

      return stc_result([targets[choice].bank, targets[choice].position])
    end

    # Method that show the item choice
    # @return [PFM::ItemDescriptor::Wrapper, nil]
    def show_item_choice
      cc 0x01
      puts 'No driver for Item choice yet...'
      return nil
    end

    # Method that show the pokemon choice
    # @param forced [Boolean]
    # @return [PFM::PokemonBattler, nil]
    def show_pokemon_choice(forced = false)
      party = retrieve_party.select { |pokemon| pokemon.position < 0 }
      if party.empty?
        cc 0x01
        puts 'No Pokemon to switch!'
        return nil
      end
      pokemon = nil
      until pokemon
        choice = @scene.display_message('Which Pokemon to send?', 1, *party.map(&:to_s))
        pokemon = party[choice]
        return pokemon unless forced
      end
      return pokemon
    end

    # Make the result of show_target_choice method
    # @param result [Array, :auto, :cancel]
    def stc_result(result = :auto)
      return nil if result == :cancel

      arr = [@pokemon_choice, @move_choice]
      if result.is_a?(Array)
        arr.concat(result)
      elsif result == :auto
        targets = @move_choice.battler_targets(@pokemon_choice, @scene.logic)
        if targets.empty?
          arr.concat([1, 0])
        else
          arr << targets.first.bank
          arr << targets.first.position
        end
      else
        return nil
      end
      arr << false
      return arr
    end

    # Show HP animations
    # @param targets [Array<PFM::PokemonBattler>]
    # @param hps [Array<Integer>]
    # @param effectiveness [Array<Integer, nil>]
    # @param messages [Proc] messages shown right before the post processing
    def show_hp_animations(targets, hps, effectiveness = [], &messages)
      targets.each_with_index do |target, index|
        if hps[index] > 0
          cc 0x01
          puts "#{target} lost #{hps[index]} HP."
        elsif hps[index] < 0
          cc 0x02
          puts "#{target} gained #{hps[index]} HP."
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
        cc 0x01
        puts parse_text_with_pokemon(19, 0, target, PFM::Text::PKNICK[0] => target.given_name)
        target.status = 0
      end
    end

    # Show the ability animation
    # @param target [PFM::PokemonBattler]
    # @param [Boolean] no_go_out Set if the out animation should be not played automatically
    def show_ability(target, no_go_out = false)
      cc 0x05
      puts "#{target.given_name}'s #{target.ability_name}"
    end
    alias hide_ability void

    # Show the item user animation
    # @param target [PFM::PokemonBattler]
    def show_item(target)
      cc 0x06
      puts "#{target.given_name}'s #{target.item_name}"
    end
    alias show_switch_form_animation void

    alias show_move_animation void
    alias show_rmxp_animation void

    # Show the exp distribution
    # @param exp_data [Hash{ PFM::PokemonBattler => Integer }] info about experience each pokemon should receive
    def show_exp_distribution(exp_data)
      cc 0x01
      puts 'Exp distribution disabled in Console Battle'
    end

    # Show the catching animation
    # @param target_pokemon [PFM::PokemonBattler] pokemon being caught
    # @param ball [GameData::Ball] ball used
    # @param nb_bounce [Integer] number of time the ball move
    # @param caught [Integer] if the pokemon got caught
    def show_catch_animation(target_pokemon, ball, nb_bounce, caught)
      cc 0x01
      puts 'Caching disabled in Console Battle'
    end

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
    end

    class MockedMessage < MockedBattlerSprite
      attr_accessor :blocking, :wait_input, :position_overwrite, :windowskin_overwrite, :nameskin_overwrite, :line_number_overwrite, :width_overwrite,
                    :drawing_message, :auto_skip, :stay_visible, :input_number_window

      alias initialize void
    end
  end
end
