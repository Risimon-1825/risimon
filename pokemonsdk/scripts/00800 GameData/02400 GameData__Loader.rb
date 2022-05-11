# If PSDK works in 4G mode or not
# @note Not implemented yet
GameData::Flag_4G = false

module GameData
  module_function

  def load
    # Load natures
    GameData::Natures.load
    # Load association abilityID -> TextID
    GameData::Abilities.load
    # Load all data sources
    GameData::DataSource::SOURCES.each(&:load)
    # Load Maplinks
    $game_data_maplinks = load_data('Data/PSDK/Maplinks.rxdata')
    # Load SystemTags
    $data_system_tags = load_data('Data/PSDK/SystemTags.rxdata')
    # Load Quests
    GameData::Quest.load
  end
end

Graphics.on_start do
  GameData.load
end
