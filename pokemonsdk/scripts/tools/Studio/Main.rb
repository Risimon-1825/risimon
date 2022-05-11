# frozen_string_literal: true

# Script helping Pokemon Studio & PSDK to communicate
# This script is automatically launched if psdk was launched with studio argument
module Studio
  module_function

  # Load the studio interface
  def start
    return if @handler

    ScriptLoader.start
    ScriptLoader.load_tool('Studio/Handler')
    @handler = Handler.new
    @handler.start
  end
end

require 'json'

module Kernel
  def puts(*args)
    STDOUT.puts({
      type: :kernel_puts,
      message: args.join("\n").gsub(/\033\[[0-9]+m/, '')
    }.to_json)
  end

  def p(*args)
    STDOUT.puts({
      type: :kernel_p,
      message: args.map(&:inspect).join("\n").gsub(/\033\[[0-9]+m/, '')
    }.to_json)
  end

  def print(*args)
    STDOUT.puts({
      type: :kernel_print,
      message: args.join.gsub(/\033\[[0-9]+m/, '')
    }.to_json)
  end
end
