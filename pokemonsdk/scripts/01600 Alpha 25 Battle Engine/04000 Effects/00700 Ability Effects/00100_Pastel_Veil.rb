module Battle
  module Effects
    class Ability
      class PastelVeil < Ability
        # Poison status
        POISON = %i[poison toxic]

        # Create a new FlowerGift effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the ability
        def initialize(logic, target, db_symbol)
          super
          @affect_allies = true
        end

        # Function called when a status_prevention is checked
        # @param handler [Battle::Logic::StatusChangeHandler]
        # @param status [Symbol] :poison, :toxic, :confusion, :sleep, :freeze, :paralysis, :burn, :flinch, :cure
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, nil] :prevent if the status cannot be applied
        def on_status_prevention(handler, status, target, launcher, skill)
          return if target.bank != @target.bank
          return unless POISON.include?(status)
          return unless launcher&.can_be_lowered_or_canceled?

          return handler.prevent_change do
            handler.scene.visual.show_ability(@target)
            handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 252, @target))
          end
        end

        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return if with != @target || who == with

          targets = @logic.adjacent_allies_of((@target))
          targets.each do |target|
            next if !target.status_effect.poison? && !target.status_effect.toxic?

            @logic.scene.visual.show_ability(@target)
            @logic.status_change_handler.status_change(:cure, target)
            @logic.scene.display_message_and_wait(parse_text_with_pokemon(19, 246, @target))
          end
        end
      end
      register(:pastel_veil, PastelVeil)
    end
  end
end
