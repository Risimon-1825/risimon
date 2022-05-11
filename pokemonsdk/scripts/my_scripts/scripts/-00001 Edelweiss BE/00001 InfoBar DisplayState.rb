module Battle
  class Visual
    alias psdk_set_info_state set_info_state
    # Set the state info
    # @param state [Symbol] kind of state (:choice, :move, :move_animation)
    # @param pokemon [Array<PFM::PokemonBattler>] optional list of Pokemon to show (move)
    def set_info_state(state, pokemon = nil)
      if state == :choice
        show_info_bars(bank: 1)
        show_info_bars(bank: 0)
        show_team_info
      else
        psdk_set_info_state(state, pokemon)
      end
    end
  end
end
