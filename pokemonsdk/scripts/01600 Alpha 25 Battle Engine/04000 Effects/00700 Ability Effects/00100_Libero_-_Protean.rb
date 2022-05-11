module Battle
  module Effects
    class Ability
      class Libero < Ability
        # Function called when a damage_prevention is checked
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_damage_prevention(handler, hp, target, launcher, skill)
          if launcher.ability_db_symbol == :libero || launcher.ability_db_symbol == :protean
            handler.scene.visual.show_ability(launcher)
            launcher.type1 = skill.type
            launcher.type2 = 0
            text = parse_text_with_pokemon(19, 899, launcher, PFM::Text::PKNICK[0] => launcher.given_name,
                                                          '[VAR TYPE(0001)]' => data_type(skill.type).name)
            handler.scene.display_message_and_wait(text)
          end
        end

        # Function called when a status_prevention is checked
        # @param handler [Battle::Logic::StatusChangeHandler]
        # @param status [Symbol] :poison, :toxic, :confusion, :sleep, :freeze, :paralysis, :burn, :flinch, :cure
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, nil] :prevent if the status cannot be applied
        def on_status_prevention(handler, status, target, launcher, skill)
          if launcher.ability_db_symbol == :libero || launcher.ability_db_symbol == :protean
            handler.scene.visual.show_ability(launcher)
            launcher.type1 = skill.type
            launcher.type2 = 0
            text = parse_text_with_pokemon(19, 899, launcher, PFM::Text::PKNICK[0] => launcher.given_name,
                                                          '[VAR TYPE(0001)]' => data_type(skill.type).name)
            handler.scene.display_message_and_wait(text)
          end
        end

        # Function called when a stat_change is about to be applied
        # @param handler [Battle::Logic::StatChangeHandler]
        # @param stat [Symbol] :atk, :dfe, :spd, :ats, :dfs, :acc, :eva
        # @param power [Integer] power of the stat change
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [Integer, nil] if integer, it will change the power
        def on_stat_change(handler, stat, power, target, launcher, skill) 
          if launcher.ability_db_symbol == :libero || launcher.ability_db_symbol == :protean
            handler.scene.visual.show_ability(launcher)
            launcher.type1 = skill.type
            launcher.type2 = 0
            text = parse_text_with_pokemon(19, 899, launcher, PFM::Text::PKNICK[0] => launcher.given_name,
                                                          '[VAR TYPE(0001)]' => data_type(skill.type).name)
            handler.scene.display_message_and_wait(text)
          end
        end
      end
      register(:libero, Libero)
      register(:protean, Libero)
    end
  end
end
