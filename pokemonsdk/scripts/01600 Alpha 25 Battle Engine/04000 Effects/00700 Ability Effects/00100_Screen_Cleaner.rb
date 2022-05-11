module Battle
  module Effects
    class Ability
      class ScreenCleaner < Ability
        WALLS = %i[light_screen reflect aurora_veil]
        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return if with != @target || who == with

          handler.scene.visual.show_ability(@target)
          bank_foes = handler.logic.adjacent_foes_of(@target).map(&:bank).first
          suppr_reflect(bank_foes)
          bank_allies = handler.logic.adjacent_allies_of(@target).map(&:bank).first
          suppr_reflect(bank_allies)
        end

        # Function called to suppr the reflect effect
        # @param bank [Object] bank of the battlers
        def suppr_reflect(bank)
          @logic.bank_effects[bank].each do |effect|
            next unless WALLS.include?(effect.name)

            if effect.name == :reflect
              @logic.scene.display_message_and_wait(parse_text(18, bank == 0 ? 132 : 133))
            elsif effect.name == :light_screen
              @logic.scene.display_message_and_wait(parse_text(18, bank == 0 ? 136 : 137))
            else
              @logic.scene.display_message_and_wait(parse_text(18, bank == 0 ? 140 : 141))
            end
            log_info("PSDK Screen Cleaner: #{effect.name} effect removed.")
            effect.kill
          end
        end
      end
      register(:screen_cleaner, ScreenCleaner)
    end
  end
end
