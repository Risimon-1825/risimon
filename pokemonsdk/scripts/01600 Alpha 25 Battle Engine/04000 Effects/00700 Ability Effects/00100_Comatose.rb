module Battle
  module Effects
    class Ability
      class Comatose < Ability
        STATUS = %i[toxic poison burn paralysis freeze sleep]
        # Function called when a status_prevention is checked
        # @param handler [Battle::Logic::StatusChangeHandler]
        # @param status [Symbol] :poison, :toxic, :confusion, :sleep, :freeze, :paralysis, :burn, :flinch, :cure
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, nil] :prevent if the status cannot be applied
        def on_status_prevention(handler, status, target, launcher, skill)
          return unless STATUS.include?(status)

          return handler.prevent_change do
            handler.scene.display_message_and_wait(parse_text(18, 74))
          end
        end
      end
      register(:comatose, Comatose)
    end
  end
end
