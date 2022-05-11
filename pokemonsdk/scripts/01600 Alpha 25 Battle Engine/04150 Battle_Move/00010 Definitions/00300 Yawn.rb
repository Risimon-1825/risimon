module Battle
  class Move
    # Class that manage the Yawn skill, works together with the Effects::Drowsiness class
    # @see https://bulbapedia.bulbagarden.net/wiki/Yawn_(move)
    class Yawn < Move
      private

      # Tell if the move accuracy is bypassed
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @return [Boolean]
      def bypass_accuracy?(user, targets)
        return true
      end

      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super

        if targets.all? { |target| target.effects.has?(:drowsiness) || target.effects.has?(:substitute) || target.has_ability?(:comatose) } ||
           @logic.terrain_effects.has?(:electric_terrain) && targets.all?(&:grounded?)
          show_usage_failure(user)
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
        return true if super
        return failure_message if target.effects.has?(:drowsiness) || target.effects.has?(:substitute) || target.has_ability?(:comatose)
        return failure_message if @logic.terrain_effects.has?(:electric_terrain) && target.grounded?
        return true unless logic.status_change_handler.status_appliable?(:sleep, target, user)

        return false
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          target.effects.add(Effects::Drowsiness.new(@logic, target, turn_count))
        end
        return true
      end

      # Return the turn countdown before the effect proc (including the current one)
      # @return [Integer]
      def turn_count
        2
      end

      # Display failure message
      # @return [Boolean] true if blocked
      def failure_message
        @logic.scene.display_message_and_wait(parse_text(18, 74))
        return true
      end
    end
    Move.register(:s_yawn, Yawn)
  end
end
