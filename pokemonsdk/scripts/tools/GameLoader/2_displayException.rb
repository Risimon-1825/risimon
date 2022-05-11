# Function that display an exception with a message and clean up
# @param message [String] message for the exception
def display_game_exception(message)
  STDERR.puts message
  STDERR.puts format('Error type : %<class>s', class: $!.class)
  STDERR.puts format('Error message : %<message>s', message: $!.message)
  STDERR.puts $!.backtrace
  Audio.bgm_stop rescue nil
  Audio.bgs_stop rescue nil
  Audio.me_stop rescue nil
  Audio.se_stop rescue nil
  FMOD::System.close rescue nil
  exit!
end
