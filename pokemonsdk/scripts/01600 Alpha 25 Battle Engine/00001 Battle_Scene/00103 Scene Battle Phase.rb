module Battle
  class Scene
    private

    # Method that add the actions of the player, sort them and let the main phase process
    def start_battle_phase
      log_info('Starting battle phase')
      # Add player actions
      @logic.add_actions(@player_actions.flatten)
      @player_actions.clear
      @logic.sort_actions
      @message_window.width = @visual.viewport.rect.width if @visual.viewport
      @message_window.wait_input = true
      # Tell to call update_battle_phase on the next frame
      @next_update = :update_battle_phase
    end

    # Method that makes the battle logic perform an action
    # @note Should call the after_action_dialog event
    def update_battle_phase
      return if @logic.perform_next_action

      # If the battle logic couldn't perform the next action (ie there's nothing to do)
      # We call the after_action_dialog event, check if the battle can continue and choose the right thing to do
      call_event(:after_action_dialog)
      if @logic.can_battle_continue?
        @logic.battle_phase_end
        @next_update = @logic.can_battle_continue? ? :player_action_choice : :battle_end
      else
        @next_update = :battle_end
      end
    end

    # Method that perform everything that needs to be performed at battle end (phrases etc...) and gives back the master to Scene_Map
    def battle_end
      log_info('Exiting battle')
      @battle_result = @logic.battle_result
      @logic.battle_end_handler.process
      $game_temp.in_battle = false
      $game_temp.battle_proc&.call(@battle_result)
      $game_temp.battle_proc = nil
      return_to_last_scene
    end

    # Method that tells to return to the last scene (Scene_Map)
    def return_to_last_scene
      $scene = Scene_Map.new
      @running = false
    end
  end
end
