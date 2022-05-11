# Scenarize Battles

In PSDK (since .25.5) it is possible to use "battle event". Those events are ruby script that allow you to make the battle a bit more lively by showing messages (like Mid battle dialogue) or some other things.

## What can Battle Event do?

The Battle event can do several things, one of the most obvious one is: showing a message. But there's two other things you can do:
* Setting the state of the logic once it has been loaded (eg. adding initial battle effect)
* Forcing the AI to do a specific action

Those things are gives real power on the Battle. It's not always easy to write specific AI (for gym leader or elite) so using Battle event is a good alternative.

## How to create battle events

Battle event are stored into `Data/Events/Battle` as Ruby files. The filename must follow a specific pattern: 5 digit followed by anything, followed by the `.rb` extension.

Example: `Data/Events/Battle/00234 Brock battle.rb` is a valid name.

Note: The digits are the most important part because they are figured out by `Battle::Logic::BattleInfo#battle_id`

## How to define which events to load

In PSDK `Battle::Logic::BattleInfo#battle_id` tells which event to load. For example if `battle_id` is equal to 5, `Data/Events/Battle/00005*.rb` will be loaded. You have two solution to define this value. Either you use `Battle::Logic::BattleInfo` (see: [Create Trainer With Script](/#%20Create%20Trainer%20With%20Script.md")) or set `Battle Group ID` to a non-null value in `Ruby Host`.

Note: Wild battle always use `battle_id = 1` unless you manually call `$wild_battle.setup(battle_id)`.

Warning: You should avoid making several files with the same digits (eg. `00005 Brock battle.rb` and `00005 Misty battle.rb`) PSDK will load the wrong file.

## What are the exact event the battle scene is looking for ?

Currently PSDK look at 5 kind of events. In this section we will detail all the event you can use.

### `Battle::Scene.register_event(:logic_init)`

This event is called when `Battle::Scene.new` is called and all the important instance of the battle scene has been initialized. It allows you to setup some effects in the logic if you want to make the battle a bit more interesting. Example:

```ruby
Battle::Scene.register_event(:logic_init) do |scene|
  scene.logic.bank_effects[1].add(Battle::Effects::LightScreen.new(scene.logic, 1, 0, Float::INFINITY))
  scene.logic.bank_effects[1].add(Battle::Effects::Reflect.new(scene.logic, 1, 0, Float::INFINITY))
end
```

This event will set the LightScreen & Reflect effect on enemy side for an infinite amount of turn.

### `Battle::Scene.register_event(:battle_begin)`

This event is called when the player & enemy just sent out their Pokémon and right before the player chooses what to do. This allows you to add more stuff than just "X sends Y out". Example:

```ruby
Battle::Scene.register_event(:battle_begin) do |scene|
  scene.show_event_message('Ah Ah! I\'m so bad I need light screen & reflect effect on battle field by default!') # It's calling scene.visual.lock ;)
end
```

Note: `show_event_message` is not a standard function! You need the following script to be able to use it:
```ruby
module Battle
  class Scene
    # Show messages from enemy trainer during battle
    # @para messages [Array<String>]
    # @note this function calls visual.lock
    def show_event_message(*messages)
      visual.lock do
        sp = visual.battler_sprite(1, -1) # Trainer sprites are in negative part: -1 = 1st trainer sprite
        # => Show enemy trainer sprite
        animation_to_left = Yuki::Animation.move(0.4, sp, 320 + sp.width, sp.y, 290, sp.y)
        animation_to_left.start
        visual.animations << animation_to_left
        visual.hide_team_info
        visual.wait_for_animation

        # => Show all messages
        messages.each do |message|
          # Tell message box to let player read
          message_window.blocking = true
          message_window.wait_input = true
          # Actually show the message
          display_message_and_wait(message)
        end

        # => Hide enemy trainer sprite
        animation_to_right = Yuki::Animation.move(0.4, sp, 290, sp.y, 320 + sp.width, sp.y)
        animation_to_right.start
        visual.animations << animation_to_right
        visual.show_team_info
        visual.wait_for_animation
      end
    end
  end
end
```

### `Battle::Scene.register_event(:trainer_dialog)`

This event is called right after the player choosed what to do and right before the AI choose what to do. Example:

```ruby
Battle::Scene.register_event(:trainer_dialog) do |scene|
  next if $game_temp.battle_turn != 1 # 1 = first turn

  scene.show_event_message('Oh, I forgot to tell you, I had no intention to fight :p') # It's calling scene.visual.lock ;)
end
```

### `Battle::Scene.register_event(:AI_force_action)`

This event gets called when the AI what to do. Since battle can involve several AI it will be called as much as the battle has AI. So right after the `scene` parameter you have the `ai` and `index` parameter giving you all the information about the AI you might force the action. 

Since an AI can control more than one Pokémon, the event should return an array of actions if the actions are forced. Otherwise return nil and PSDK will use the default AI behavior.

Example:
```ruby
Battle::Scene.register_event(:AI_force_action) do |scene, ai, index|
  next if index != 0 # We only care about the first AI

  controlled_pokemon = ai.controlled_pokemon
  next if controlled_pokemon.empty? # Safety net
  next unless scene.logic.can_battler_be_replaced?(ai_pokemon = controlled_pokemon.first) # Don't try to switch if we can't

  allies = ai.party.select { |pokemon| pokemon.alive? && !controlled_pokemon.include?(pokemon) }
  next if allies.empty? # Safety net

  next [Battle::Actions::Switch.new(scene, ai_pokemon, allies.sample)]
end
```
This event will force the AI to swicth the Pokemon to a random Pokémon of its own Party.

### `Battle::Scene.register_event(:after_action_dialog)`

This event is called after all move got proceed and right before the enemy sends out another Pokémon (in case of KO). If you want to do DPP gym leader event that's what you might need to use!

Example:
```ruby
Battle::Scene.register_event(:after_action_dialog) do |scene|
  next if scene.artificial_intelligences[0].party.count { |pokemon| pokemon.alive? } > 1
  next if scene.instance_variable_get(:@event_last_dialog_executed)

  scene.instance_variable_set(:@event_last_dialog_executed, true) # Ensure the event does not get called gain
  scene.show_event_message('Oh no! I can no longer switch :(') # It's calling scene.visual.lock ;)
end
```

## Full demonstration

If you want to try this out, you can create an event which execute the following Ruby command:
```ruby
gv[31] = 2 # Set transition to RBY
bi = Battle::Logic::BattleInfo.new
bi.add_party(0, *bi.player_basic_info)
party = []
party << PFM::Pokemon.new(25, 15)
party << PFM::Pokemon.new(52, 15)
party << PFM::Pokemon.new(8, 15)
bi.add_party(1, party, 'Yuri', 'Bad Trainer', 'dp_33', nil, 255, 7)
bi.battle_id = 2 # Tell battle to load Data/Events/Battle/00002*.rb
$scene.call_scene(Battle::Scene, bi) # Call the battle
```

Then create the file `Data/Events/Battle/00002 Demo.rb` with the following content:
```ruby
# Register init logic event
# This kind of event will be called before the scene actually transition,
# the goal if that event is to setup the logic the way you want.
#
# In this example, we will setup light screen & reflect on AI side with infinite amount of turns
Battle::Scene.register_event(:logic_init) do |scene|
  scene.logic.bank_effects[1].add(Battle::Effects::LightScreen.new(scene.logic, 1, 0, Float::INFINITY))
  scene.logic.bank_effects[1].add(Battle::Effects::Reflect.new(scene.logic, 1, 0, Float::INFINITY))

  # Here we will define utility function on the visual because we call something that does not exist quite often
  # It's highly recommanded that you make a script that add this function to Battle::Scene instead of doing it here
  # We can't just add this to PSDK by default because all games are different!
  def scene.show_event_message(*messages)
    visual.lock do
      sp = visual.battler_sprite(1, -1) # Trainer sprites are in negative part: -1 = 1st trainer sprite
      # => Show enemy trainer sprite
      animation_to_left = Yuki::Animation.move(0.4, sp, 320 + sp.width, sp.y, 290, sp.y)
      animation_to_left.start
      visual.animations << animation_to_left
      visual.hide_team_info
      visual.wait_for_animation

      # => Show all messages
      messages.each do |message|
        # Tell message box to let player read
        message_window.blocking = true
        message_window.wait_input = true
        # Actually show the message
        display_message_and_wait(message)
      end

      # => Hide enemy trainer sprite
      animation_to_right = Yuki::Animation.move(0.4, sp, 290, sp.y, 320 + sp.width, sp.y)
      animation_to_right.start
      visual.animations << animation_to_right
      visual.show_team_info
      visual.wait_for_animation
    end
  end
end

# Register battle begin event
# This kind of event will be called right after everyone sent out their Pokémon and
# just before the player makes the first choice.
# In this kind of event, you can show some pre-battle dialogs or anything else you want.
# Don't forget to call scene.visual.lock otherwise you might get some troubles!
#
# In this example we'll show the 1st AI and make it says something
Battle::Scene.register_event(:battle_begin) do |scene|
  scene.show_event_message('Ah Ah! I\'m so bad I need light screen & reflect effect on battle field by default!') # It's calling scene.visual.lock ;)
end

# Register trainer dialog event
# This kind of event is called after player made a choice and right before AI make any choice
# Don't forget to call scene.visual.lock otherwise you might get some troubles!
#
# In this example we'll make the enemy trainer say something on 1st turn
Battle::Scene.register_event(:trainer_dialog) do |scene|
  next if $game_temp.battle_turn != 1 # 1 = first turn

  scene.show_event_message('Oh, I forgot to tell you, I had no intention to fight :p') # It's calling scene.visual.lock ;)
end

# Register AI force action event
# This kind of event is called for all AI, it should return an Array of Battle::Actions::Base (or nil)
# This allows you to force the AI to make an action
#
# In this example, we'll make the 1st AI switch
Battle::Scene.register_event(:AI_force_action) do |scene, ai, index|
  next if index != 0

  controlled_pokemon = ai.controlled_pokemon
  next if controlled_pokemon.empty? # Safety net
  next unless scene.logic.can_battler_be_replaced?(ai_pokemon = controlled_pokemon.first) # Don't try to switch if we can't

  allies = ai.party.select { |pokemon| pokemon.alive? && !controlled_pokemon.include?(pokemon) }
  next if allies.empty? # Safety net

  next [Battle::Actions::Switch.new(scene, ai_pokemon, allies.sample)]
end

# Register after action dialog event
# This kind of event is called right after all the actions got executed but right before ai send out Pokemon after KO
# Don't forget to call scene.visual.lock otherwise you might get some troubles!
#
# In this example, I'll wait that the 1st AI party has no more Pokemon to switch and make the enemy say something about it
Battle::Scene.register_event(:after_action_dialog) do |scene|
  next if scene.artificial_intelligences[0].party.count { |pokemon| pokemon.alive? } > 1
  next if scene.instance_variable_get(:@event_last_dialog_executed)

  scene.instance_variable_set(:@event_last_dialog_executed, true)
  scene.show_event_message('Oh no! I can no longer switch :(') # It's calling scene.visual.lock ;)
end
```

And finaly try this event :)
