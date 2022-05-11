module Battle
  class Simulator < Scene
    def process_moves_over_mono_type
      $scene = self
      remove_all_logs
      pokemon_db_symbols = all_pokemon_by_mono_type
      pokemon_db_symbols.each do |target_db_symbol|
        process_move_over_target(target_db_symbol)
      end
    end

    def process_move_over_target(target_db_symbol)
      t = time
      @output.truncate(0)
      @output.pos = 0
      load_pokemon(:__undef__, target_db_symbol)
      user = @logic.battler(0, 0)
      bm = Battle::Move
      gs = GameData::Skill
      aa = Actions::Attack
      all_moves.each do |move_db_symbol|
        st = time
        @output.puts ''.center(150, '=')
        @output.puts "<AT=TARGET:#{target_db_symbol};MOVE:#{move_db_symbol}>"
        logic.send(:init_effects)
        $env.apply_weather(0)
        reset_pokemon(user)
        user.attack_order = 0
        skill = gs[move_db_symbol]
        move = bm[skill.be_method].new(skill.id, 10, 10, self)
        if (target = move.battler_targets(user, logic).first)
          pos = [target.bank, target.position]
          if target != user
            reset_pokemon(target)
            target.attack_order = 1
          end
        else
          pos = [1, 0]
        end
        begin
          10.times do |i|
            aa.new(self, move, user, *pos).execute
            break if user.move_history.any?

            @output.puts 'LAST_NOT_SUCCESFULL: RETRYING' if i != 9
          end
        rescue Exception => e
          @output.puts "ERROR: #{e.message} (#{e.class})"
          @output.puts e.backtrace
        end
        @output.puts "<AT_DURATION:#{time - st}>"
      end
      @output.puts ''.center(150, '=')
      @output.puts "<AT_TOTAL_DURATION:#{time - t}>"
      File.write("output/#{target_db_symbol}.txt", @output.string)
    end

    private

    def all_pokemon_by_mono_type
      GameData::Pokemon.all[0].first.type1 = 0
      GameData::Pokemon.all[0].first.type2 = 0
      GameData::Pokemon.all[1..].select { |i| i.first.type2 == 0 }.uniq { |i| i.first.type1 }.map(&:first).map(&:db_symbol)
    end

    def all_moves
      GameData::Skill.all.uniq { |i| [i.be_method, i.type, i.power, i.accuracy, i.priority] }.map(&:db_symbol)
    end
  end
end
