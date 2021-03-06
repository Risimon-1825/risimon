# Script generated by StateMachineBuilder
# Generation Date: 2021-08-14 12:01:05
__LINE__.to_i

module GamePlay
  # Scene asking the player to provide the time
  #
  # How to use:
  # 1. Set time with no initial time
  #   call_scene(GamePlay::RSEClock) { |scene| @time = "#{scene.hour}:#{scene.minute}"}
  # 2. Set time with initial time
  #   call_scene(GamePlay::RSEClock, hour, minute) { |scene| @time = "#{scene.hour}:#{scene.minute}"}
  class RSEClock < GamePlay::StateMachine
    include GamePlay::RSEClockHelpers::Logic
    include GamePlay::RSEClockHelpers::UI
    include GamePlay::RSEClockHelpers::Questions

    # Constant holding all the update method to call depending on the state
    STATE_UPDATE_METHODS = {
      init: :update_init,
      choice: :update_choice,
      inc_min: :update_inc_min,
      dec_min: :update_dec_min,
      wait: :update_wait,
      confirmation: :update_confirmation,
      out: :update_out
    }

    private

    # Function that initialize the state machine, please, do not forget to call this function where it makes sense (depending on dependencies)
    def initialize_state_machine
      @smi_a = Input.trigger?(:A)
      @smi_left = Input.press?(:LEFT)
      @smi_right = Input.press?(:RIGHT)
      @smi_choice = @choice_result
      @smi_waiter_done = @waiter&.done?
      @sm_state = :init
    end

    # Function that call the right update method, don't forget to call it if you're not inheriting from a class that calls it
    def update_state_machine
      send(STATE_UPDATE_METHODS[@sm_state])
    end

    def update_init
      update_aiguilles
      @sm_state = :choice
    end

    def tansitioning_from_choice_to_inc_min?
      @smi_right == true
    end

    def tansitioning_from_choice_to_dec_min?
      @smi_left == true
    end

    def tansitioning_from_choice_to_confirmation?
      @smi_a == true
    end

    def update_state_from_choice
      return @sm_state = :inc_min if tansitioning_from_choice_to_inc_min?
      return @sm_state = :dec_min if tansitioning_from_choice_to_dec_min?
      return @sm_state = :confirmation if tansitioning_from_choice_to_confirmation?
    end

    def update_choice_inputs
      @smi_right = Input.press?(:RIGHT)
      @smi_left = Input.press?(:LEFT)
      @smi_a = Input.trigger?(:A)
    end

    def update_choice
      update_choice_inputs
      update_state_from_choice
    end

    def update_inc_min
      increase_minutes
      update_aiguilles
      @sm_state = :wait
    end

    def update_dec_min
      decrease_minutes
      update_aiguilles
      @sm_state = :wait
    end

    def tansitioning_from_wait_to_choice?
      @smi_waiter_done == true
    end

    def update_state_from_wait
      return @sm_state = :choice if tansitioning_from_wait_to_choice?
    end

    def update_wait_inputs
      @smi_waiter_done = @waiter&.done?
    end

    def update_wait
      update_waiter
      update_wait_inputs
      update_state_from_wait
    end

    def tansitioning_from_confirmation_to_out?
      @smi_choice == :YES
    end

    def tansitioning_from_confirmation_to_choice?
      @smi_choice == :NO
    end

    def update_state_from_confirmation
      return @sm_state = :out if tansitioning_from_confirmation_to_out?
      return @sm_state = :choice if tansitioning_from_confirmation_to_choice?
    end

    def update_confirmation_inputs
      @smi_choice = @choice_result
    end

    def update_confirmation
      ask_confirmation
      update_confirmation_inputs
      update_state_from_confirmation
    end

    def update_out
      exit_state_machine
      # This is a dead end.
    end
  end
end
