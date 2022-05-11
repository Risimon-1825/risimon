# Create Trainer with Script

In this tutorial we will see the true power of .25: creating any kind of trainer battle through the unique Battle Information interface (aka. `Battle::Logic::BattleInfo`).

For now, you should be used to create a trainer in `Ruby Host` or `Studio` and then start the battle with either of those three functions: 
- `start_trainer_battle`
- `start_double_trainer_battle`
- `start_double_trainer_battle_with_friend`

This is kind of great but there's some limitations to those functions:
1. The team is "static" meaning that each call of those function with the same parameter will almost give the same result (putting aside few random attributes of Pokémon if they were random)
2. Rivals become a bit incoherent if you forgot to lock some attribute like gender.
3. You can't build Battle Frontier battles without going crazy (presetting 1000+ battles with GUI is just a huge waste of time)
4. In `Ruby Host`, you can't define the bag of the trainers
5. Names will always be the same for a specific trainer

## What is `Battle::Logic::BattleInfo`

This class describe all the basic information the Battle Scene needs to start and process the battle. When you start a battle you're actually passing a `Battle::Logic::BattleInfo` object to `Battle::Scene#initialize`.

This object allow you to configure things like:
- What are the trainer that are battleing (it can be a battle without Player)
- What is the victory and battle bgm
- Is there a level limit to the battle (thus battle is not providing any exp)
- What is the battle id (to define the events of the battle)

Here's the documentation about this object: [BattleInfo Ruby Doc](https://psdk.pokemonworkshop.fr/yard/Battle/Logic/BattleInfo.html)

## How to use the `Battle::Logic::BattleInfo` object

### First step, creating a `Battle::Logic::BattleInfo` object

The `Battle::Logic::BattleInfo` is a data object, it accepts a Hash in initialize allowing you to instanciate almost all attributes of the object (regardless we will just focus on basic attributes). We will call this object battle info.

When you create a `Battle::Logic::BattleInfo` object you want to define the following attributes:
- `battle_bgm`: Music played when the battle starts
- `victory_bgm`: Music played when the battle ends on Victory
- `vs_type`: Number of Pokemon on each bank
- `max_level`: Maximum level of Pokemons in the Battle (Pokemon are brough back to this level if their level is higher)
- `fishing`: If the battle result from using a Rod.

Of course, those attributes are not mandatory, they all have default value and some like `battle_bgm` or `victory_bgm` will rely on what's configured using Event Commands.

Here's few example of Battle Info definition:
```ruby
# Battle info that will be 1v1 by default and only provides the audio filenames (meaning volume and pitch are 100)
bi_1v1_music_with_only_filenames = Battle::Logic::BattleInfo.new(
  battle_bgm: 'audio/bgm/rosa_wild_battle',
  victory_bgm: 'audio/bgm/xy_trainer_battle_victory'
)
# Battle info that will be 2v2 with a level restriction of lv.70 providing full info for battle bgm but leaving RMXP choose victory BGM.
bi_2v2_max_level_70 = Battle::Logic::BattleInfo.new(
  vs_type: 2,
  max_level: 70,
  battle_bgm: ['audio/bgm/rosa_wild_battle', 80, 100],
)
# Battle info that will be 1v1 and leave RMXP choose BGM info
bi = Battle::Logic::BattleInfo.new
```

### Second step, feeding the Battle info with Player's data

Most of the time you want to start a trainer battle involving the Player. It can be annoying to grab all the info about the player so the Battle Info interace provides you with a function that gives you all the basic information about the player:
- It's Sprite (based on RMXP battler name or player charset_base if not defined)
- It's Party
- It's name
- It's bag

The trainer class will be the trainer class 0 by default (but since it's not shown on player side, it shouldn't be such a big deal).

To feed the battle info with a trainer data we call the function `add_party` with the bank and then the data. The player is always on bank 0 so to feed the battle info with player's data you write this line:
```ruby
# here bi contains the Battle::Logic::BattleInfo object that was initialized in previous step
bi.add_party(0, *bi.player_basic_info)
```

### Third step, feeding the Battle info with the Trainer's data

In the previous step we did not see what exactly are the paramters of `add_party`. It's time to see them because to feed trainer's data we need to know what to provide.

The method `add_party` currently have 8 parameters. The two first are mandatory, bank & party. If you only provide the two first parameter on bank 1, you'll end up in Wild Battle (because the Battle Info state that a battle is Trainer battle if enemy side has names). Here's the list of parameter in order:
- `bank`: The bank where the party is sent, 0 (player's bank) or 1 (enemy's bank)
- `party`: An array of PFM::Pokemon describing all the Pokémon in the currently added party
- `name`: The name of the trainer if it's Trainer Battle
- `klass`: The name of the class of the trainer if it's Trainer Battle (eg. "Pkmn Trainer")
- `battler`: The Sprite filename in `graphics/battlers` for the trainer
- `bag`: Bag of the trainer (the AI will use this bag to decide which item to use)
- `base_money`: The base money given by the trainer (total money is base_money * level of last pokemon)
- `ai_level`: The AI level of the trainer

Here's a complete example where we setup the bag, party and ask to use the strongest default AI:
```ruby
# here bi contains the Battle::Logic::BattleInfo object that was initialized in first step
party = []
party << PFM::Pokemon.generate_from_hash(id: :mew, level: 100, shiny: true, given_name: 'Destroyer', trainer_name: 'Yuri', trainer_id: 0)
party << PFM::Pokemon.generate_from_hash(id: :arceus, level: 100, given_name: 'I\'m weak', trainer_name: 'Yuri', trainer_id: 0)
party << PFM::Pokemon.generate_from_hash(id: :gardevoir, level: 100, given_name: 'MEGA Devoirs', trainer_name: 'Yuri', trainer_id: 0, item: :gardevoirite)
bag = PFM::Bag.new
bag.add_item(:full_restore, 50)
bag.add_item(:mega_glasses, 1) # Allow enemy to mega evolve
bi.add_party(1, party, 'Yuri', 'Bad Trainer', 'dp_33', bag, 255, 7)
```

### Final step, starting the battle

Once everything has properly been setup we can start the battle using the following command:
```ruby
# here bi contains the Battle::Logic::BattleInfo object that was initialized in first step
$scene.call_scene(Battle::Scene, bi)
```

Here's the full script command put together:
```ruby
bi = Battle::Logic::BattleInfo.new
bi.add_party(0, *bi.player_basic_info)
party = []
party << PFM::Pokemon.generate_from_hash(id: :mew, level: 100, shiny: true, given_name: 'Destroyer', trainer_name: 'Yuri', trainer_id: 0)
party << PFM::Pokemon.generate_from_hash(id: :arceus, level: 100, given_name: 'I\'m weak', trainer_name: 'Yuri', trainer_id: 0)
party << PFM::Pokemon.generate_from_hash(id: :gardevoir, level: 100, given_name: 'MEGA Devoirs', trainer_name: 'Yuri', trainer_id: 0, item: :gardevoirite)
bag = PFM::Bag.new
bag.add_item(:full_restore, 50)
bag.add_item(:mega_glasses, 1) # Allow enemy to mega evolve
bi.add_party(1, party, 'Yuri', 'Bad Trainer', 'dp_33', bag, 255, 7)
$scene.call_scene(Battle::Scene, bi)
```

## Final word

We've seen how to start trainer battle from script with fully customized trainer. Now we should be able to define any kind of battle using this method, it would allow you to setup battle based on player's level, or based on player's party. It's your call to write the scripts that setup the battle info properly so it does what you want to!

In the next tutorials we'll see how to make team based on Player's team and how to setup battle with Friend trainer. (If you followed this tutorial, you might already be able to do it by simply adding a second team to bank 0).