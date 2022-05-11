module Battle
  module Effects
    class Ability
      # A Pokemon with Telepathy avoids damaging moves used by its allies.
      # @see https://pokemondb.net/ability/telepathy
      # @see https://bulbapedia.bulbagarden.net/wiki/Telepathy_(Ability)
      class Telepathy < Ability
        # Function called when a damage_prevention is checked
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, Integer, nil] :prevent if the damage cannot be applied, Integer if the hp variable should be updated
        def on_damage_prevention(handler, hp, target, launcher, skill)
          return if target != @target
          return unless launcher&.can_be_lowered_or_canceled?

          allies = handler.logic.allies_of(target)
          allies.each do |ally|
            next unless launcher == ally && hp > 0

            handler.scene.visual.show_ability(target)
            handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 469, target))
            return :prevent
          end
          return nil
        end
      end
      register(:telepathy, Telepathy)
    end
  end
end