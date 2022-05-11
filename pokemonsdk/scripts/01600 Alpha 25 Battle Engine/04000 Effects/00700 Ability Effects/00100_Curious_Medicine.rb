module Battle
  module Effects
    class Ability
      class CuriousMedicine < Ability
        # Create a new FlowerGift effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the ability
        def initialize(logic, target, db_symbol)
          super
          @affect_allies = true
        end

        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return if with != @target || who == with

          targets = @logic.adjacent_allies_of(@target)
          targets.each do |target|
            next if target.battle_stage.none? { |stage| stage != 0 }

            handler.scene.visual.show_ability(@target)
            target.battle_stage.map! { 0 }
            handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 195, target))
          end
        end
      end
      register(:curious_medicine, CuriousMedicine)
    end
  end
end
