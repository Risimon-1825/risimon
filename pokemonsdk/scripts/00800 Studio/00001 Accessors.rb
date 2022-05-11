class Object
  private

  # Get an ability
  # @param db_symbol [Symbol] db_symbol of the ability
  # @return [GameData::Abilities::Model]
  def data_ability(db_symbol)
    return GameData::Abilities::Model.new(db_symbol) if db_symbol.is_a?(Integer)

    return GameData::Abilities::Model.new(GameData::Abilities.find_using_symbol(db_symbol) || 0)
  end

  # Iterate through all abilities
  # @yieldparam ability [GameData::Abilities::Model]
  # @return [Enumerator<GameData::Abilities::Model>]
  def each_data_ability
    return to_enum(__method__) unless block_given?

    GameData::Abilities.psdk_id_to_gf_id.size.times do |i|
      yield(GameData::Abilities::Model.new(i))
    end
  end

  # Get an item
  # @param db_symbol [Symbol] db_symbol of the item
  # @return [GameData::Item]
  def data_item(db_symbol)
    return GameData::Item[db_symbol]
  end

  # Iterate through all items
  # @yieldparam item [GameData::Item]
  # @return [Enumerator<GameData::Item>]
  def each_data_item(&block)
    return to_enum(__method__) unless block_given?

    GameData::Item.all[1..].each(&block)
  end

  # Get a move
  # @param db_symbol [Symbol] db_symbol of the move
  # @return [GameData::Skill]
  def data_move(db_symbol)
    return GameData::Skill[db_symbol]
  end

  # Iterate through all the moves
  # @yieldparam move [GameData::Skill]
  # @return [Enumerator<GameData::SKill>]
  def each_data_move(&block)
    return to_enum(__method__) unless block_given?

    GameData::Skill.all[1..].each(&block)
  end

  # Get a creature
  # @param db_symbol [Symbol] db_symbol of the creature
  # @return [GameData::Pokemon::PokemonBase]
  def data_creature(db_symbol)
    return GameData::Pokemon[db_symbol]
  end
  alias data_pokemon data_creature

  # Get a creature form
  # @param db_symbol [Symbol] db_symbol of the creature
  # @param form [Integer] form of the creature
  # @return [GameData::Pokemon]
  def data_creature_form(db_symbol, form)
    creature = GameData::Pokemon[db_symbol]
    return creature.forms.find { |creature_form| creature_form.form == form } || creature.forms[0]
  end

  # Iterate through all the creatures
  # @yieldparam move [GameData::Pokemon::PokemonBase]
  # @return [Enumerator<GameData::Pokemon::PokemonBase>]
  def each_data_creature
    return to_enum(__method__) unless block_given?

    GameData::Pokemon.all[1..].each { |creature| yield(creature[0]) }
  end

  # Get a quest
  # @param id [Integer] ID of the quest
  # @return [GameData::Quest, nil]
  def data_quest(id)
    return GameData::Quest[id]
  end

  # Iterate throug all the quests
  # @yieldparam quest [GameData::Quest]
  # @return [Enumerator<GameData::Quest>]
  def each_data_quest(&block)
    return to_enum(__method__) unless block_given?

    GameData::Quest.all.each(&block)
  end

  # Get a trainer
  # @param id [Integer] ID of the trainer
  # @return [GameData::Trainer, nil]
  def data_trainer(id)
    return GameData::Trainer[id]
  end

  # Iterate throug all the trainers
  # @yieldparam trainer [GameData::Trainer]
  # @return [Enumerator<GameData::Trainer>]
  def each_data_trainer(&block)
    return to_enum(__method__) unless block_given?

    GameData::Trainer.all.each(&block)
  end

  # Get a type
  # @param db_symbol [Symbol] db_symbol of the type
  # @return [GameData::Type]
  def data_type(db_symbol)
    return GameData::Type[db_symbol]
  end

  # Iterate throug all the types
  # @yieldparam type [GameData::Type]
  # @return [Enumerator<GameData::Type>]
  def each_data_type(&block)
    return to_enum(__method__) unless block_given?

    GameData::Type.all.each(&block)
  end

  # Get a zone
  # @param id [Symbol] id of the zone
  # @return [GameData::Zone, nil]
  def data_zone(id)
    return GameData::Zone[id]
  end

  # Iterate throug all the zones
  # @yieldparam zone [GameData::Zone]
  # @return [Enumerator<GameData::Zone>]
  def each_data_zone(&block)
    return to_enum(__method__) unless block_given?

    GameData::Zone.all.each(&block)
  end
end
