# This script allow to convert the project to a PSDK Editor Project
#
# To get access to this script write :
#   ScriptLoader.load_tool('PSDKEditor')
#
# To execute this script write :
#   PSDKEditor.convert
module PSDKEditor
  # Root folder of the PSDK Editor data
  ROOT = 'Data/Studio'
  # Root folder of the PSDK config
  ROOT_CONFIGS = 'Data/configs'

  module_function

  # Convert the project to a PSDK Editor Project
  def convert
    create_paths
    convert_pokemon
    convert_items
    convert_types
    convert_moves
    convert_zones
    convert_worldmaps
    convert_trainers
    convert_quests
    convert_abilities
    convert_configs
  end

  # Function that creates all the necessary path
  def create_paths
    Dir.mkdir(ROOT) unless Dir.exist?(ROOT)
    all_paths = %w[pokemon items types moves zones worldmaps trainers quests abilities groups].map { |dirname| File.join(ROOT, dirname) }
    all_paths.each do |path|
      Dir.mkdir(path) unless Dir.exist?(path)
    end
  end

  # Return the filename of a csv file
  # @param csv_id [Integer]
  # @return [String]
  def csv_filename(csv_id)
    format('Data/Text/Dialogs/%<file_id>d.csv', file_id: csv_id)
  end

  # Create a csv file if doesn't exist
  # @param csv_id [Integer]
  # @param data [Array<Array>]
  def create_csv(csv_id, data)
    return if File.exist?(csv_filename(csv_id))

    data.unshift(%w[en fr it de es ko kana])
    CSV.open(csv_filename(csv_id), 'w') do |csv|
      data.each { |row| csv << row }
    end
  end

  # Function that convert Item data to PSDK Editor format
  def convert_items
    GameData::Item.all.each do |item|
      item_data = {
        klass: item.class.to_s.split(':').last, id: item.id, dbSymbol: item.db_symbol,
        icon: item.icon, price: item.price, socket: item.socket, position: item.position, isBattleUsable: item.battle_usable,
        isMapUsable: item.map_usable, isLimited: item.limited, isHoldable: item.holdable, flingPower: item.fling_power,
        **item.extra_psdk_editor_data
      }
      next if check_db_symbol(item)

      File.write(File.join(ROOT, 'items', "#{item.db_symbol}.json"), item_data.to_json)
    end
  end

  # Function that convert Type data to PSDK Editor format
  def convert_types
    GameData::Type.all.each_with_index do |type, index|
      type_data = {
        textId: type.text_id, klass: 'Type', id: type.id, dbSymbol: type.db_symbol,
        damageTo: GameData::Type.all.map do |def_type|
          def_type.on_hit_tbl[index] != 1 ? { defensiveType: def_type.db_symbol, factor: def_type.on_hit_tbl[index] } : nil
        end.compact
      }
      next if check_db_symbol(type)

      File.write(File.join(ROOT, 'types', "#{type.db_symbol}.json"), type_data.to_json)
    end
  end

  # Function that convert Move data to PSDK Editor format
  def convert_moves
    attack_category = %w[physical physical special status]
    GameData::Skill.all.each do |move|
      move_data = {
        id: move.id, dbSymbol: move.db_symbol, klass: 'Move', mapUse: move.map_use, battleEngineMethod: move.be_method,
        type: GameData::Type[move.type].db_symbol, power: move.power, accuracy: move.accuracy, pp: move.pp_max,
        category: attack_category[move.atk_class], movecriticalRate: move.critical_rate,
        priority: move.priority + Battle::Logic::MOVE_PRIORITY_OFFSET, isDirect: move.direct, isCharge: move.charge, isRecharge: move.recharge,
        isBlocable: move.blocable, isSnatchable: move.snatchable, isMirrorMove: move.mirror_move, isPunch: move.punch, isGravity: move.gravity,
        isMagicCoatAffected: move.magic_coat_affected, isUnfreeze: move.unfreeze, isSoundAttack: move.sound_attack, isDistance: move.distance,
        isHeal: move.heal, isAuthentic: move.authentic, isBite: move.bite, isPulse: move.pulse, isBallistics: move.ballistics,
        isMental: move.mental, isNonSkyBattle: move.non_sky_battle, isDance: move.dance, isKingRockUtility: move.king_rock_utility,
        isPowder: move.powder, isEffectChance: move.effect_chance == 100, battleEngineAimedTarget: move.target,
        battleStageMod: move.battle_stage_mod.map.with_index do |value, index|
          value != 0 ? { battleStage: GameData::Stages::PSDK_EDITOR_VALUES[index], modificator: value } : nil
        end.compact
      }
      move_data.merge!(moveStatus: [{ status: GameData::States::PSDK_EDITOR_VALUES[move.status], luckRate: move.effect_chance }]) if move.status
      next if check_db_symbol(move)

      File.write(File.join(ROOT, 'moves', "#{move.db_symbol}.json"), move_data.to_json)
    end
  end

  # Function that convert the Zone data to PSDK Editor format
  def convert_zones
    GameData::Zone.all.each do |zone|
      zone_data = {
        id: zone.id, dbSymbol: "zone_#{zone.id}", klass: 'Zone', maps: [zone.map_id].compact.flatten, worldmaps: [zone.worldmap_id].flatten,
        pannelId: zone.panel_id, warp: { x: zone.warp_x, y: zone.warp_y }, position: { x: zone.pos_x, y: zone.pos_y }, isFlyAllowed: zone.fly_allowed,
        isWarpDisallowed: zone.warp_disallowed, forcedWeather: zone.forced_weather, wildGroups: create_wild_groups(zone)
      }
      File.write(File.join(ROOT, 'zones', "zone_#{zone.id}.json"), zone_data.to_json)
    end
    group_names = []
    @group_index.times do |i|
      group_name = Array.new(7, "Group #{i}")
      group_name[1] = "Groupe #{i}"
      group_names << group_name
    end
    create_csv(100_061, group_names)
  end

  # Function that convert the WorldMap data to PSDK Editor format
  def convert_worldmaps
    GameData::WorldMap.all.each do |worldmap|
      grid = worldmap.data.ysize.times.map { |y| worldmap.data.xsize.times.map { |x| worldmap.data[x, y] } }
      if worldmap.name_file_id.is_a?(String)
        region_name = { csvFileId: 9, csvTextIndex: 0 }
      else
        region_name = { csvFileId: worldmap.name_file_id || 9, csvTextIndex: worldmap.name_id || 0 }
      end
      worldmap_data = {
        id: worldmap.id, dbSymbol: worldmap.db_symbol, klass: 'WorldMap',
        image: worldmap.image, grid: grid,
        regionName: region_name
      }
      File.write(File.join(ROOT, 'worldmaps', "#{worldmap.id}.json"), worldmap_data.to_json)
    end
  end

  # Function that convert the trainers
  def convert_trainers
    trainer_names = []
    GameData::Trainer.all.each do |trainer|
      trainer_data = {
        klass: 'TrainerBattleSetup', id: trainer.id, dbSymbol: "trainer_#{trainer.id}",
        vsType: trainer.vs_type, isCouple: false, baseMoney: trainer.base_money,
        battlers: [trainer.battler], bagEntries: [], battleId: 0, ai: 0,
        party: [convert_trainer_party(trainer.team)]
      }
      trainer_name = trainer.internal_names.flatten.first
      trainer_names << Array.new(7, trainer_name)
      File.write(File.join(ROOT, 'trainers', "trainer_#{trainer.id}.json"), trainer_data.to_json)
    end
    create_csv(100_062, trainer_names)
  end

  # Function that convert Pokemon data to PSDK Editor format
  def convert_pokemon
    GameData::Pokemon.all.each do |entry|
      pokemon_array = Array.from(entry)
      # @type [Integer]
      id = pokemon_array.first.id
      db_symbol = pokemon_array.first.db_symbol
      move_mega_evolution(pokemon_array.compact)
      specie_data = map_pokemon_array_to_forms(pokemon_array.compact)
      next if check_db_symbol(pokemon_array.first)

      filename = File.join(ROOT, 'pokemon', "#{db_symbol}.json")
      File.write(filename, { id: id, dbSymbol: db_symbol, forms: specie_data, klass: 'Specie' }.to_json)
    end
  end

  # Function that map a Pokemon Array to a form list
  # @param pokemon_array [Array<GameData::Pokemon>]
  # @return [Array<Hash>]
  def map_pokemon_array_to_forms(pokemon_array)
    return pokemon_array.map do |pokemon|
      next {
        form: pokemon.form, height: pokemon.height, weight: pokemon.weight, type1: GameData::Type[pokemon.type1].db_symbol,
        type2: GameData::Type[pokemon.type2].db_symbol, baseHp: pokemon.base_hp, baseAtk: pokemon.base_atk, baseDfe: pokemon.base_dfe,
        baseSpd: pokemon.base_spd, baseAts: pokemon.base_ats, baseDfs: pokemon.base_dfs, evHp: pokemon.ev_hp, evAtk: pokemon.ev_atk,
        evDfe: pokemon.ev_dfe, evSpd: pokemon.ev_spd, evAts: pokemon.ev_ats, evDfs: pokemon.ev_dfs, evolutions: build_evolutions(pokemon),
        experienceType: pokemon.exp_type, baseExperience: pokemon.base_exp, baseLoyalty: pokemon.base_loyalty, catchRate: pokemon.rareness,
        femaleRate: pokemon.female_rate, breedGroups: pokemon.breed_groupes, hatchSteps: pokemon.hatch_step,
        babyDbSymbol: !pokemon.baby || pokemon.baby == 0 ? '__undef__' : GameData::Pokemon[pokemon.baby].db_symbol, 
        babyForm: pokemon.form && pokemon.form < 30 ? pokemon.form : 0,
        itemHeld: pokemon.items.each_slice(2).map { |(id, chance)| { dbSymbol: GameData::Item[id].db_symbol, chance: chance.to_i } },
        abilities: pokemon.abilities.map { |id| GameData::Abilities.db_symbol(id) }, frontOffsetY: pokemon.front_offset_y.to_i,
        moveSet: build_moveset(pokemon)
      }
    end
  end

  # Function that builds the moveset of a Pokemon
  # @param pokemon [GameData::Pokemon]
  # @return [Array<Hash>]
  def build_moveset(pokemon)
    # @type [Array]
    moveset = pokemon.move_set.each_slice(2).select { |(level, _)| level > 0 }
                     .map { |(level, id)| { klass: 'LevelLearnableMove', level: level, move: GameData::Skill[id].db_symbol } }
    moveset.concat(pokemon.master_moves.map { |id| { klass: 'TutorLearnableMove', move: GameData::Skill[id].db_symbol } })
    moveset.concat(pokemon.tech_set.map { |id| { klass: 'TechLearnableMove', move: GameData::Skill[id].db_symbol } })
    moveset.concat(pokemon.move_set.each_slice(2).select { |(level, _)| level <= 0 }
      .map { |(_, id)| { klass: 'EvolutionLearnableMove', move: GameData::Skill[id].db_symbol } })
    moveset.concat(pokemon.breed_moves.map { |id| { klass: 'BreedLearnableMove', move: GameData::Skill[id].db_symbol } })
    return moveset
  end

  # Function that build the evolution of a Pokemon
  # @param pokemon [GameData::Pokemon]
  # @return [Array<Hash>]
  def build_evolutions(pokemon)
    evolutions = []
    if pokemon.evolution_id != 0 && pokemon.evolution_level && pokemon.evolution_level != 0
      data = { conditions: [] }
      data[:dbSymbol] = GameData::Pokemon[pokemon.evolution_id].db_symbol
      data[:form] = pokemon.form
      data[:conditions] << { type: :minLevel, value: pokemon.evolution_level }
      evolutions << data
    end
    return evolutions unless pokemon.special_evolution

    pokemon.special_evolution.each do |evolution|
      data = { conditions: [] }
      data[:dbSymbol] = GameData::Pokemon[evolution[:id]].db_symbol if evolution[:id]
      data[:form] = evolution[:form] || pokemon.form
      data[:conditions] << { type: :minLevel, value: evolution[:min_level] } if evolution[:min_level]
      data[:conditions] << { type: :maxLevel, value: evolution[:max_level] } if evolution[:max_level]
      data[:conditions] << { type: :tradeWith, value: GameData::Pokemon[evolution[:trade_with]].db_symbol } if evolution[:trade_with]
      if evolution[:trade]
        data[:conditions] << { type: :trade, value: true }
        data[:dbSymbol] = GameData::Pokemon[evolution[:trade]].db_symbol
      end
      data[:conditions] << { type: :stone, value: GameData::Item[evolution[:stone]].db_symbol } if evolution[:stone]
      data[:conditions] << { type: :itemHold, value: GameData::Item[evolution[:item_hold]].db_symbol } if evolution[:item_hold]
      data[:conditions] << { type: :minLoyalty, value: evolution[:min_loyalty] } if evolution[:min_loyalty]
      data[:conditions] << { type: :maxLoyalty, value: evolution[:max_loyalty] } if evolution[:max_loyalty]
      data[:conditions] << { type: :skill1, value: GameData::Skill[evolution[:skill_1]].db_symbol } if evolution[:skill_1]
      data[:conditions] << { type: :skill2, value: GameData::Skill[evolution[:skill_2]].db_symbol } if evolution[:skill_2]
      data[:conditions] << { type: :skill3, value: GameData::Skill[evolution[:skill_3]].db_symbol } if evolution[:skill_3]
      data[:conditions] << { type: :skill4, value: GameData::Skill[evolution[:skill_4]].db_symbol } if evolution[:skill_4]
      data[:conditions] << { type: :weather, value: evolution[:weather] } if evolution[:weather]
      data[:conditions] << { type: :env, value: evolution[:env] } if evolution[:env]
      data[:conditions] << { type: :gender, value: evolution[:gender] } if evolution[:gender]
      data[:conditions] << { type: :dayNight, value: evolution[:day_night] } if evolution[:day_night]
      data[:conditions] << { type: :func, value: evolution[:func] } if evolution[:func]
      data[:conditions] << { type: :maps, value: evolution[:maps] } if evolution[:maps]
      data[:conditions] << { type: :gemme, value: GameData::Item[evolution[:gemme]].db_symbol } if evolution[:gemme]
      evolutions << data
    end
    return evolutions
  end

  # Move mega evolution (the evolution of the mega evolved form is moved in the form 0)
  # @param pokemon_array [Array<GameData::Pokemon>]
  def move_mega_evolution(pokemon_array)
    pokemon_array.each do |pokemon|
      next if !pokemon.form || pokemon.form < 30
      next unless pokemon.special_evolution

      pokemon_array.first.special_evolution = [] unless pokemon_array.first.special_evolution
      pokemon.special_evolution.each do |evolution|
        next unless evolution[:gemme]

        data = {}
        data[:form] = pokemon.form
        data[:gemme] = evolution[:gemme]
        pokemon_array.first.special_evolution.push << data
      end
      pokemon.special_evolution = []
    end
  end

  GROUP_TOOLS = { 8 => 'OldRod', 9 => 'GoodRod', 10 => 'SuperRod', 11 => 'RockSmash', 12 => 'HeadButt' }
  GROUP_ZONE_SYSTEM_TAG = %w[RegularGround Grass TallGrass Cave Mountain Sand Pond UnderWater Snow Ice]
  @group_index = 0
  # Function that creates the wild groups of a Zone
  # @param zone
  def create_wild_groups(zone)
    group_db_symbols = []
    zone.groups&.each do |group|
      group_terrain_tag = group[1] >= 8 ? { tool: GROUP_TOOLS[group[1]], terrainTag: 0 } : { terrainTag: group[1] }
      sw = group.instance_variable_get(:@enable_switch)
      map_id = group.instance_variable_get(:@map_id) || 0
      custom_conditions = []
      custom_conditions << { type: :enabledSwitch, value: sw, relationWithPreviousCondition: 'AND' } if sw
      custom_conditions << { type: :mapId, value: map_id, relationWithPreviousCondition: 'AND' } if map_id != 0
      group_data = {
        klass: 'Group',
        id: @group_index,
        dbSymbol: "group_#{@group_index}",
        systemTag: GROUP_ZONE_SYSTEM_TAG[group.first],
        doubleBattle: group[3] == 2,
        hordeBattle: false,
        customConditions: custom_conditions,
        encounters: create_wild_encounters(group[2], group[4..-1].each_slice(3).to_a),
        **group_terrain_tag
      }
      group_db_symbols << "group_#{@group_index}"
      File.write(File.join(ROOT, 'groups', "group_#{@group_index}.json"), group_data.to_json)
      @group_index += 1
    end
    return group_db_symbols
  end

  # Function that create the wild encounter setup
  # @param delta [Integer]
  # @param encounters [Array<Array>]
  # @return [Array<Hash>]
  def create_wild_encounters(delta, encounters)
    minus = (-(delta - 1) / 2).clamp(-999, 0)
    plus = delta / 2
    return encounters.map do |(id, level, chance)|
      if level.is_a?(Hash)
        pkmn = level
        level = level[:level]
        setup = {
          specie: GameData::Pokemon[id].db_symbol, form: pkmn[:form] || 0, shinySetup: shiny_setup(pkmn),
          levelSetup: {
            kind: 'minmax',
            level: {
              minimumLevel: (level + minus).clamp(1, PSDK_CONFIG.pokemon_max_level),
              maximumLevel: (level + plus).clamp(1, PSDK_CONFIG.pokemon_max_level)
            }
          },
          randomEncounterChance: chance,
          expandPokemonSetup: expand_pokemon_setup(pkmn)
        }
        next setup
      else
        next {
          specie: GameData::Pokemon[id].db_symbol, form: 0, shinySetup: { kind: 'automatic', rate: -1 },
          levelSetup: {
            kind: 'minmax',
            level: {
              minimumLevel: (level + minus).clamp(1, PSDK_CONFIG.pokemon_max_level),
              maximumLevel: (level + plus).clamp(1, PSDK_CONFIG.pokemon_max_level)
            }
          },
          randomEncounterChance: chance,
          expandPokemonSetup: []
        }
      end
    end
  end

  # Function that creates the Trainer party
  # @param party [Array<Hash>]
  # @return [Array<Hash>]
  def convert_trainer_party(party)
    return party.map do |pkmn|
      setup = {
        specie: GameData::Pokemon[pkmn[:id]].db_symbol, form: pkmn[:form] || 0, shinySetup: shiny_setup(pkmn),
        levelSetup: { kind: 'fixed', level: pkmn[:level] },
        randomEncounterChance: 1,
        expandPokemonSetup: expand_pokemon_setup(pkmn)
      }
      next setup
    end
  end

  # Function that setup the shiny properties
  # @param pkmn [Hash] pokemon data to use to expand the setup
  # @return [Hash]
  def shiny_setup(pkmn)
    shiny_setup = { kind: 'automatic', rate: -1 }
    shiny_setup = { kind: 'rate', rate: 1 } if pkmn[:shiny]
    shiny_setup = { kind: 'rate', rate: 0 } if pkmn[:no_shiny]
    return shiny_setup
  end

  # Function that expands the Pokemon setup with the extended data
  # @param pkmn [Hash] pokemon data to use to expand the setup
  # @return [Array<Hash>]
  def expand_pokemon_setup(pkmn)
    pokemon_setup = []
    pokemon_setup << { type: :givenName, value: pkmn[:given_name] } if pkmn[:given_name]
    pokemon_setup << { type: :caughtWith, value: GameData::Item[pkmn[:captured_with]].db_symbol } if pkmn[:captured_with]
    pokemon_setup << { type: :gender, value: pkmn[:gender] } if pkmn[:gender]
    pokemon_setup << { type: :nature, value: convert_natures(pkmn[:nature]) } if pkmn[:nature]
    pokemon_setup << { type: :ivs, value: %i[hp atk dfe spd ats dfs].map.with_index { |stat, i| [stat, pkmn[:stats][i]] }.to_h } if pkmn[:stats]
    pokemon_setup << { type: :evs, value: %i[hp atk dfe spd ats dfs].map.with_index { |stat, i| [stat, pkmn[:bonus][i]] }.to_h } if pkmn[:bonus]
    pokemon_setup << { type: :itemHeld, value: GameData::Item[pkmn[:item]].db_symbol } if pkmn[:item]
    pokemon_setup << { type: :ability, value: GameData::Abilities.db_symbol(pkmn[:ability]) } if pkmn[:ability]
    pokemon_setup << { type: :rareness, value: pkmn[:rareness] } if pkmn[:rareness]
    pokemon_setup << { type: :loyalty, value: pkmn[:loyalty] } if pkmn[:loyalty]
    pokemon_setup << { type: :moves, value: pkmn[:moves].map { |id| GameData::Skill[id].db_symbol } } if pkmn[:moves]
    pokemon_setup << { type: :originalTrainerName, value: pkmn[:trainer_name] } if pkmn[:trainer_name]
    pokemon_setup << { type: :originalTrainerId, value: pkmn[:trainer_id] } if pkmn[:trainer_id]
    return pokemon_setup
  end

  # Function that converts the Pokemon natures from ID to String
  # @param nature [Integer] current Pokemon nature
  # @return [String]
  def convert_natures(nature)
    return nature if nature.is_a?(Symbol)

    return text_get(8, nature).downcase
  end

  # Function that converts the quests
  def convert_quests
    GameData::Quest.all.each do |quest|
      quest_data = {
        klass: 'Quest', id: quest.id, dbSymbol: "quest_#{quest.id}", isPrimary: quest.primary, resolution: 'default',
        objectives: build_objectives(quest.objectives),
        earnings: build_earnings(quest.earnings)
      }
      File.write(File.join(ROOT, 'quests', "quest_#{quest.id}.json"), quest_data.to_json)
    end
  end

  # Function that builds the objective of a quest
  # @param objectives [Array<GameData::Quest::Objective>] the objectives of the quest
  # @return [Array<Hash>]
  def build_objectives(objectives)
    return objectives.map do |objective|
      next {
        objectiveMethodName: objective.test_method_name,
        objectiveMethodArgs: build_objective_method_args(objective),
        textFormatMethodName: objective.text_format_method_name,
        hiddenByDefault: objective.hidden_by_default
      }
    end
  end

  # Function that build the objective method arguments
  # @param objective [GameData::Quest::Objective] an objectif of the quest
  # @return [Array]
  def build_objective_method_args(objective)
    case objective.test_method_name
    when :objective_obtain_item
      return [GameData::Item[objective.test_method_args[0]].db_symbol, objective.test_method_args[1]]
    when :objective_see_pokemon
      return [GameData::Pokemon[objective.test_method_args[0]].db_symbol]
    when :objective_beat_pokemon
      return [GameData::Pokemon[objective.test_method_args[0]].db_symbol, objective.test_method_args[1]]
    when :objective_catch_pokemon
      return [build_conditions_catch_pokemon(objective.test_method_args[0]), objective.test_method_args[1]]
    end

    return objective.test_method_args
  end

  # Function that builds the earning of a quest
  # @param earnings [Array<GameData::Quest::Earnings>] earnings of the quest
  # @return [Array<Hash>]
  def build_earnings(earnings)
    return earnings.map do |earning|
      next {
        earningMethodName: earning.give_method_name,
        earningArgs: build_earning_args(earning),
        textFormatMethodName: earning.text_format_method_name
      }
    end
  end

  # Function that build the earning method arguments
  # @param earning [GameData::Quest::Earnings] an earning of the quest
  # @return [Array]
  def build_earning_args(earning)
    method_name = earning.give_method_name
    if method_name == :earning_item
      item_id = earning.give_args[0]
      return [GameData::Item[item_id].db_symbol, earning.give_args[1]]
    end
    return earning.give_args
  end

  # Function build the conditions for the catch pokemon objective
  # @param pokemon [Hash, Integer] the hash or the id of the Pokemon
  # @return [Hash, Symbol]
  def build_conditions_catch_pokemon(pokemon)
    conditions = []
    if pokemon.is_a?(Integer)
      conditions << { type: 'pokemon', value: GameData::Pokemon[pokemon].db_symbol }
      return conditions
    end
    conditions << { type: 'pokemon', value: GameData::Pokemon[pokemon[:id]].db_symbol } if pokemon[:id]
    conditions << { type: 'type', value: GameData::Type[pokemon[:type]].db_symbol } if pokemon[:type]
    conditions << { type: 'nature', value: convert_natures(pokemon[:nature]) } if pokemon[:nature]
    conditions << { type: 'minLevel', value: pokemon[:min_level] } if pokemon[:min_level]
    conditions << { type: 'maxLevel', value: pokemon[:max_level] } if pokemon[:max_level]
    conditions << { type: 'level', value: pokemon[:level] } if pokemon[:level]
    return conditions
  end

  # Function that convert Abilities data to PSDK Editor format
  def convert_abilities
    GameData::Abilities.db_symbols.each do |ability_db_symbol|
      id = GameData::Abilities.find_using_symbol(ability_db_symbol)
      ability_data = {
        klass: 'Ability', dbSymbol: ability_db_symbol, id: id, textId: GameData::Abilities.psdk_id_to_gf_id[id]
      }
      next if %i[none __undef__ egg].include?(ability_db_symbol)

      File.write(File.join(ROOT, 'abilities', "#{ability_db_symbol}.json"), ability_data.to_json)
    end
  end

  # Function that check the db_symbol
  # @param data [GameData::Base] a game data
  # @return [Boolean] true if db_symbol is null or equals to :none, :undef, :egg
  def check_db_symbol(data)
    return true unless data.db_symbol

    return %i[none __undef__ egg].include?(data.db_symbol)
  end

  # Function that convert PSDK config to PSDK Editor format
  def convert_configs
    convert_infos_settings
    convert_language_settings
    convert_settings
    convert_texts_settings
    convert_game_options_settings
    convert_devices_settings
    convert_display_settings
    convert_graphic_settings
    convert_save_settings
    convert_scene_title_settings
    convert_credits_settings
  end

  # Function that convert PSDK config infos settings to PSDK Editor format
  def convert_infos_settings
    data_infos = { klass: 'InfosConfig' }
    data_infos[:gameTitle] = PSDK_CONFIG.game_title
    data_infos[:gameVersion] = PSDK_CONFIG.game_version
    File.write(File.join(ROOT_CONFIGS, 'infos_config.json'), data_infos.to_json)
  end

  # Function that convert PSDK config language settings to PSDK Editor format
  def convert_language_settings
    data_language = { klass: 'LanguageConfig' }
    data_language[:defaultLanguage] = PSDK_CONFIG.default_language_code
    data_language[:choosableLanguageCode] = PSDK_CONFIG.choosable_language_code
    data_language[:choosableLanguageTexts] = PSDK_CONFIG.choosable_language_texts
    File.write(File.join(ROOT_CONFIGS, 'language_config.json'), data_language.to_json)
  end

  # Function that convert PSDK config settings to PSDK Editor format
  def convert_settings
    data_settings = { klass: 'SettingsConfig' }
    data_settings[:pokemonMaxLevel] = PSDK_CONFIG.pokemon_max_level
    data_settings[:isAlwaysUseForm0ForEvolution] = PSDK_CONFIG.always_use_form0_for_evolution
    data_settings[:isUseForm0WhenNoEvolutionData] = PSDK_CONFIG.use_form0_when_no_evolution_data
    File.write(File.join(ROOT_CONFIGS, 'settings_config.json'), data_settings.to_json)
  end

  # Function that convert PSDK config texts settings to PSDK Editor format
  def convert_texts_settings
    data_texts = { klass: 'TextsConfig' }
    data_texts[:fonts] = build_fonts
    data_texts[:messages] = build_messages
    data_texts[:choices] = build_choices
    File.write(File.join(ROOT_CONFIGS, 'texts_config.json'), data_texts.to_json)
  end

  # Function build fonts for PSDK config texts
  def build_fonts
    data_fonts = {}
    data_fonts[:isSupportsPokemonNumber] = PSDK_CONFIG.layout.general.supports_pokemon_number
    data_fonts[:ttfFiles] = []
    data_fonts[:altSizes] = []
    PSDK_CONFIG.layout.general.ttf_files.each do |ttf_file|
      data_ttf_file = {}
      data_ttf_file[:id] = ttf_file[:id]
      data_ttf_file[:name] = ttf_file[:name]
      data_ttf_file[:size] = ttf_file[:size]
      data_ttf_file[:lineHeight] = ttf_file[:line_height]
      data_fonts[:ttfFiles] << data_ttf_file
    end
    PSDK_CONFIG.layout.general.alt_sizes.each do |alt_size|
      data_alt_size = {}
      data_alt_size[:id] = alt_size[:id]
      data_alt_size[:size] = alt_size[:size]
      data_alt_size[:lineHeight] = alt_size[:line_height]
      data_fonts[:altSizes] << data_alt_size
    end
    return data_fonts
  end

  # Function build messages for PSDK config texts
  def build_messages
    messages = {}
    # @type key [String]
    # @type psdk_message [ScriptLoader::PSDKConfig::LayoutConfig::Message]
    PSDK_CONFIG.layout.messages.each do |key, psdk_message|
      message = {}
      message[:windowSkin] = psdk_message.windowskin
      message[:nameWindowSkin] = psdk_message.name_windowskin
      message[:lineCount] = psdk_message.line_count
      message[:borderSpacing] = psdk_message.border_spacing
      message[:defaultFont] = psdk_message.default_font
      message[:defaultColor] = psdk_message.default_color
      message[:colorMapping] = psdk_message.color_mapping
      messages[key.to_sym] = message
    end
    return messages
  end

  # Function build choices for PSDK config texts
  def build_choices
    choices = {}
    # @type key [String]
    # @type psdk_choice [ScriptLoader::PSDKConfig::LayoutConfig::Choice]
    PSDK_CONFIG.layout.choices.each do |key, psdk_choice|
      choice = {}
      choice[:windowSkin] = psdk_choice.windowskin
      choice[:borderSpacing] = psdk_choice.border_spacing
      choice[:defaultFont] = psdk_choice.default_font
      choice[:defaultColor] = psdk_choice.default_color
      choice[:colorMapping] = psdk_choice.color_mapping
      choices[key.to_sym] = choice
    end
    return choices
  end

  # Function that convert PSDK config game options settings to PSDK Editor format
  def convert_game_options_settings
    data_game_options = { klass: 'GameOptionsConfig' }
    data_game_options[:order] = PSDK_CONFIG.options.order
    data_game_options[:options] = PSDK_CONFIG.options.options
    File.write(File.join(ROOT_CONFIGS, 'game_options_config.json'), data_game_options.to_json)
  end

  # Function that convert PSDK config devices settings to PSDK Editor format
  def convert_devices_settings
    data_devices = { klass: 'DevicesConfig' }
    data_devices[:isMouseDisabled] = PSDK_CONFIG.mouse_disabled
    data_devices[:mouseSkin] = PSDK_CONFIG.mouse_skin
    File.write(File.join(ROOT_CONFIGS, 'devices_config.json'), data_devices.to_json)
  end

  # Function that convert PSDK config display settings to PSDK Editor format
  def convert_display_settings
    data_display = { klass: 'DisplayConfig' }
    game_resolution = PSDK_CONFIG.native_resolution.split('x').collect(&:to_i)
    data_display[:gameResolution] = { x: game_resolution.first, y: game_resolution.last }
    data_display[:windowScale] = PSDK_CONFIG.window_scale
    data_display[:isFullscreen] = PSDK_CONFIG.running_in_full_screen
    data_display[:isPlayerAlwaysCentered] = PSDK_CONFIG.player_always_centered
    data_display[:tilemapSettings] = build_tilemap_settings
    File.write(File.join(ROOT_CONFIGS, 'display_config.json'), data_display.to_json)
  end

  # Function build tilemap settings for PSDK config display
  def build_tilemap_settings
    data_tilemap = {}
    data_tilemap[:tilemapClass] = PSDK_CONFIG.tilemap.tilemap_class
    data_tilemap[:tilemapSize] = { x: PSDK_CONFIG.tilemap.tilemap_size_x, y: PSDK_CONFIG.tilemap.tilemap_size_y }
    data_tilemap[:autotileIdleFrameCount] = PSDK_CONFIG.tilemap.autotile_idle_frame_count
    data_tilemap[:characterTileZoom] = PSDK_CONFIG.tilemap.character_tile_zoom
    data_tilemap[:characterSpriteZoom] = PSDK_CONFIG.tilemap.character_sprite_zoom
    data_tilemap[:center] = { x: PSDK_CONFIG.tilemap.center_x, y: PSDK_CONFIG.tilemap.center_y }
    data_tilemap[:maplinkerOffset] = { x: PSDK_CONFIG.tilemap.maplinker_offset_x, y: PSDK_CONFIG.tilemap.maplinker_offset_y }
    data_tilemap[:isOldMaplinker] = PSDK_CONFIG.tilemap.old_maplinker || false
    return data_tilemap
  end

  # Function that convert PSDK config graphic settings to PSDK Editor format
  def convert_graphic_settings
    data_graphic = { klass: 'GraphicConfig' }
    data_graphic[:isSmoothTexture] = PSDK_CONFIG.smooth_texture
    data_graphic[:isVsyncEnabled] = PSDK_CONFIG.vsync_enabled
    File.write(File.join(ROOT_CONFIGS, 'graphic_config.json'), data_graphic.to_json)
  end

  # Function that convert PSDK config save settings to PSDK Editor format
  def convert_save_settings
    data_save = { klass: 'SaveConfig' }
    data_save[:maximumSave] = Configs.save_config.maximum_save_count
    data_save[:saveKey] = Configs.save_config.save_key
    data_save[:saveHeader] = Configs.save_config.save_header
    data_save[:baseFilename] = Configs.save_config.base_filename
    data_save[:isCanSaveOnAnySave] = Configs.save_config.can_save_on_any_save
    File.write(File.join(ROOT_CONFIGS, 'save_config.json'), data_save.to_json)
  end

  # Function that convert PSDK config scene title settings to PSDK Editor format
  def convert_scene_title_settings
    data_scene_title = { klass: 'SceneTitleConfig' }
    data_scene_title[:introMovieMapId] = Configs.scene_title_config.intro_movie_map_id
    data_scene_title[:bgmName] = Configs.scene_title_config.bgm_name
    data_scene_title[:bgmDuration] = Configs.scene_title_config.bgm_duration
    data_scene_title[:isLanguageSelectionEnabled] = Configs.scene_title_config.language_selection_enabled
    data_scene_title[:additionalSplashes] = Configs.scene_title_config.additional_splashes
    data_scene_title[:controlWaitTime] = Configs.scene_title_config.control_wait
    File.write(File.join(ROOT_CONFIGS, 'scene_title_config.json'), data_scene_title.to_json)
  end

  # Function that convert PSDK config credits settings to PSDK Editor format
  def convert_credits_settings
    data_credits = { klass: 'CreditsConfig' }
    data_credits[:projectSplash] = Configs.credits_config.project_splash
    data_credits[:bgm] = Configs.credits_config.bgm
    data_credits[:lineHeight] = Configs.credits_config.line_height
    data_credits[:scrollSpeed] = Configs.credits_config.speed
    data_credits[:leaderSpacing] = Configs.credits_config.leader_spacing
    data_credits[:chiefProjectTitle] = Configs.credits_config.chief_project_title
    data_credits[:chiefProjectName] = Configs.credits_config.chief_project_name
    data_credits[:leaders] = Configs.credits_config.leaders
    data_credits[:gameCredits] = Configs.credits_config.game_credits
    File.write(File.join(ROOT_CONFIGS, 'credits_config.json'), data_credits.to_json)
  end

  # Function that convert PSDK config online settings to PSDK Editor format
  def convert_online_settings
    data_online = { klass: 'OnlineConfig' }
    data_online[:isEnabled] = Configs.online_configs.enabled
    data_online[:serverIp] = Configs.online_configs.server_ip
    data_online[:serverPort] = Configs.online_configs.server_port
    File.write(File.join(ROOT_CONFIGS, 'online_config.json'), data_online.to_json)
  end
end

module GameData
  class Item
    # Convert extra data to PSDK Editor data
    # @return [Hash]
    def extra_psdk_editor_data
      return {}
    end
  end

  class BallItem
    # Convert extra data to PSDK Editor data
    # @return [Hash]
    def extra_psdk_editor_data
      return super.merge(spriteFilename: img, catchRate: catch_rate, color: color.to_psdk_editor)
    end
  end

  class TechItem
    # Convert extra data to PSDK Editor data
    # @return [Hash]
    def extra_psdk_editor_data
      return super.merge(move: GameData::Skill[move_learnt].db_symbol, isHm: is_hm)
    end
  end

  class RepelItem
    # Convert extra data to PSDK Editor data
    # @return [Hash]
    def extra_psdk_editor_data
      return super.merge(repelCount: repel_count)
    end
  end

  class HealingItem
    # Convert extra data to PSDK Editor data
    # @return [Hash]
    def extra_psdk_editor_data
      return super.merge(loyaltyMalus: loyalty_malus)
    end
  end

  class RateHealItem
    # Convert extra data to PSDK Editor data
    # @return [Hash]
    def extra_psdk_editor_data
      return super.merge(hpRate: hp_rate)
    end
  end

  class StatusRateHealItem
    # Convert extra data to PSDK Editor data
    # @return [Hash]
    def extra_psdk_editor_data
      return super.merge(statusList: status_list.map { |state| States::PSDK_EDITOR_VALUES[state] })
    end
  end

  class ConstantHealItem
    # Convert extra data to PSDK Editor data
    # @return [Hash]
    def extra_psdk_editor_data
      return super.merge(hpCount: hp_count)
    end
  end

  class StatusConstantHealItem
    # Convert extra data to PSDK Editor data
    # @return [Hash]
    def extra_psdk_editor_data
      return super.merge(statusList: status_list.map { |state| States::PSDK_EDITOR_VALUES[state] })
    end
  end

  class StatusHealItem
    # Convert extra data to PSDK Editor data
    # @return [Hash]
    def extra_psdk_editor_data
      return super.merge(statusList: status_list.map { |state| States::PSDK_EDITOR_VALUES[state] })
    end
  end

  class EventItem
    # Convert extra data to PSDK Editor data
    # @return [Hash]
    def extra_psdk_editor_data
      return super.merge(eventId: event_id)
    end
  end

  class PPHealItem
    # Convert extra data to PSDK Editor data
    # @return [Hash]
    def extra_psdk_editor_data
      return super.merge(ppCount: pp_count)
    end
  end

  class PPIncreaseItem
    # Convert extra data to PSDK Editor data
    # @return [Hash]
    def extra_psdk_editor_data
      return super.merge(isMax: max)
    end
  end

  class LevelIncreaseItem
    # Convert extra data to PSDK Editor data
    # @return [Hash]
    def extra_psdk_editor_data
      return super.merge(levelCount: level_count)
    end
  end

  class StatBoostItem
    # Convert extra data to PSDK Editor data
    # @return [Hash]
    def extra_psdk_editor_data
      return super.merge(stat: Stages::PSDK_EDITOR_VALUES[stat_index], count: count)
    end
  end

  class EVBoostItem
    # Convert extra data to PSDK Editor data
    # @return [Hash]
    def extra_psdk_editor_data
      return super.merge(stat: EV::PSDK_EDITOR_VALUES[stat_index], count: count)
    end
  end

  module States
    # Hash helping to convert state ID to their PSDK Editor counter part
    PSDK_EDITOR_VALUES = {
      POISONED => 'POISONED', PARALYZED => 'PARALYZED', BURN => 'BURN', ASLEEP => 'ASLEEP', FROZEN => 'FROZEN', CONFUSED => 'CONFUSED',
      TOXIC => 'TOXIC', DEATH => 'DEATH', FLINCH => 'FLINCH'
    }
  end

  module Stages
    # Hash helping to convert stage ID to its PSDK Editor counter part
    PSDK_EDITOR_VALUES = {
      ATK_STAGE => 'ATK_STAGE', ATS_STAGE => 'ATS_STAGE', DFE_STAGE => 'DFE_STAGE', DFS_STAGE => 'DFS_STAGE',
      SPD_STAGE => 'SPD_STAGE', EVA_STAGE => 'EVA_STAGE', ACC_STAGE => 'ACC_STAGE'
    }
  end

  module EV
    # Hash helping to convert EV stat ID to its PSDK Editor counter part
    PSDK_EDITOR_VALUES = {
      ATK => 'ATK', ATS => 'ATS', DFE => 'DFE', DFS => 'DFS', SPD => 'SPD', HP => 'HP'
    }
  end
end

class Color
  # Convert a color in the PSDK editor format
  # @return [Hash]
  def to_psdk_editor
    {
      red: red,
      green: green,
      blue: blue,
      alpha: alpha
    }
  end
end
