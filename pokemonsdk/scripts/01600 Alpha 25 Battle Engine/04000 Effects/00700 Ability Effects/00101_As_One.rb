module Battle
  module Effects
    class Ability
      class AsOne < ChillingNeigh
        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return if with != @target

          handler.scene.visual.show_ability(with)
          handler.scene.display_message_and_wait(parse_text(18, with.bank == 0 ? 183 : 182))
        end

        private

        def boosted_stat
          return :atk
        end
      end
      register(:as_one, AsOne)

      class AsOneBis < AsOne
        private

        def boosted_stat
          return :ats
        end
      end
      register(:as_one_bis, AsOneBis)
    end
  end
end
