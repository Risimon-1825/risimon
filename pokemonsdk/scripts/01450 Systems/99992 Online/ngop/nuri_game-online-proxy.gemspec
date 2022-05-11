
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "nuri_game/online/proxy/version"

Gem::Specification.new do |spec|
  spec.name          = "nuri_game-online-proxy"
  spec.version       = NuriGame::Online::Proxy::VERSION
  spec.authors       = ["Nuri Yuri"]
  spec.email         = ["hostmaster@pokemonworkshop.com"]

  spec.summary       = %q{Utility module that implement a proxy system to allow online interactions between players}
  spec.homepage      = "https://gitlab.com/NuriYuri/nuri_game-online-proxy"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = '>= 2.5.0'

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
end
