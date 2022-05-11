def load_extension_multiplatform(extension)
  if PSDK_RUNNING_UNDER_ANDROID
    # Android cannot require locally the extension because of restrictions of the filesystem which is usually not executable
    require extension
  else
    game_deps = ENV['GAMEDEPS'] || '.'
    require PSDK_RUNNING_UNDER_WINDOWS ? "#{game_deps}/lib/#{extension}.so" : "#{game_deps}/#{extension}"
  end
end

# Load the extensions
begin
  $DEBUG = false
  STDERR.reopen(IO::NULL) if File.exist?('Data/Scripts.dat') # This should remove SFML messages (most of the time they're success)
  ENV['__GL_THREADED_OPTIMIZATIONS'] = '0'
  require 'zlib'
  require 'socket'
  require 'uri'
  require 'openssl'
  require 'net/http'
  require 'csv'
  require 'json'
  require 'yaml'
  module YAML
    unless method_defined?(:unsafe_load)
      module_function
      def unsafe_load(*args)
        load(*args)
      end
    end
  end
  # require 'rexml/document'
  load_extension_multiplatform('LiteRGSS')
  # Attempt to load audio
  begin
    load_extension_multiplatform('RubyFmod')
  rescue LoadError
    begin
      load_extension_multiplatform('SFMLAudio')
    rescue LoadError
      puts 'Could not load Audio'
    end
  end
rescue LoadError
  display_game_exception('An error occured during extensions loading.')
end

# Store the RGSS Main entry function
def rgss_main
  $GAME_LOOP = proc do
    yield
  rescue StandardError => e
    if e.class.to_s == 'Reset'
      $scene.main if $scene.is_a?(Yuki::SoftReset)
      retry
    end
  end
end
