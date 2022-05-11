module Battle
  class Move
    # Move that has a big recoil when fails
    class HighJumpKick < Basic
      # Test move accuracy
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @return [Boolean] if the move can continue
      def proceed_move_accuracy(user, targets)
        accuracy_dice = logic.move_accuracy_rng.rand(100)
        log_data("# High Jump Kick: accuracy= #{accuracy}, value = #{accuracy_dice} (testing=#{accuracy > 0}, failure=#{accuracy_dice >= accuracy})")
        if (accuracy > 0 && accuracy_dice >= accuracy) || targets.all?(&:type_ghost?)
          crash_procedure(user)
          return false
        end
        return true
      end

      # Function that tests if the targets blocks the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] expected target
      # @note Thing that prevents the move from being used should be defined by :move_prevention_target Hook.
      # @return [Boolean] if the target evade the move (and is not selected)
      def move_blocked_by_target?(user, target)
        if super
          crash_procedure(user)
          return true 
        end
        return false
      end

      # Test if the target is immune
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      # @return [Boolean]
      def target_immune?(user, target)
        return false if target.type_ghost?
        return super
      end

      # Define the crash procedure when the move isn't able to connect to the target
      # @param user [PFM::PokemonBattler] user of the move
      def crash_procedure(user)
        scene.display_message_and_wait(parse_text(18, 74))
        hp = user.max_hp / 2
        scene.visual.show_hp_animations([user], [-hp])
        scene.display_message_and_wait(parse_text_with_pokemon(19, 908, user))
      end
    end
    Move.register(:s_jump_kick, HighJumpKick)
  end
end
