# Simulator to test if moves work without crash (try to)

Usage example:
```ruby
bi = Battle::Logic::BattleInfo.new
bi.add_party(0, [PFM::Pokemon.new(25, 100)], 'Yuri', 'Bad Trainer', 'dp_33', nil, 255, 7)
bi.add_party(1, [PFM::Pokemon.new(25, 100)], 'Yuri', 'Bad Trainer', 'dp_33', nil, 255, 7)
current_scene = $scene
tester = Battle::Simulator.new(bi)
tester.process_moves_over_mono_type
$scene = current_scene
```
