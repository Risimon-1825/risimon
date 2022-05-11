# This script purpose is build a state machine in Ruby from a .yml description
#
# To get access to this call :
#   ScriptLoader.load_tool('StateMachineBuilder/StateMachineBuilder')
#
# To convert a .yml to .rb run:
#   StateMachineBuilder.run(filename)
#
# Structure of the .yml file:
#   class_name: Name of the class where the state machine built (You can use path from Object like this GameData::MyScene)
#   class_doc: Comments added on top of the class definition (No need to add the '# ' they'll be added)
#   parent_class: Name of the parent class (optional)
#   includes: List of modules to include in the class so the logic can be brought to life (state machin erase the class script)
#   input: Hash describing the ruby definition of each input of the state machine (single line!)
#   transitions: optional Hash containing references to transitions so you can give name to transitions in states definition
#   states: Hash of states by name containing the description of the states
#
# Note:
#   There's one mandatory state: init, this is the entry point of all state machines
#
# Example yml file:
#   ---
#   class_name: "GamePlay::RSEClock"
#   class_doc: |-
#     Scene asking the player to provide the time
#
#     How to use:
#     1. Set time with no initial time
#       call_scene(GamePlay::RSEClock) { |scene| @time = "#{scene.hour}:#{scene.minute}"}
#     2. Set time with initial time
#       call_scene(GamePlay::RSEClock, hour, minute) { |scene| @time = "#{scene.hour}:#{scene.minute}"}
#   parent_class: "GamePlay::StateMachineScene"
#   includes:
#   - "GamePlay::RSEClockHelpers::Logic"
#   - "GamePlay::RSEClockHelpers::UI"
#   - "GamePlay::RSEClockHelpers::Questions"
#   inputs:
#     A: "Input.trigger?(:A)"
#     LEFT: "Input.trigger?(:LEFT)"
#     RIGHT: "Input.trigger?(:RIGHT)"
#     CHOICE: "@choice_result"
#   transitions:
#     droite: &droite
#       RIGHT: true
#     gauche: &gauche
#       LEFT: true
#     A: &A
#       A: true
#     oui: &oui
#       CHOICE: :YES
#     non: &non
#       CHOICE: :NO
#   states:
#     init:
#       actions:
#         - update_aiguilles
#       transitions:
#         - to: choice
#     choice:
#       transitions:
#         - to: inc_min
#           inputs: *droite
#         - to: dec_min
#           inputs: *gauche
#         - to: confirmation
#           inputs: *A
#     inc_min:
#       actions:
#         - increase_minutes
#         - update_aiguilles
#       transitions:
#         - to: choice
#     dec_min:
#       actions:
#         - decrease_minutes
#         - update_aiguilles
#       transitions:
#         - to: choice
#     confirmation:
#       actions:
#         - ask_confirmation
#       transitions:
#         - to: out
#           inputs: *oui
#         - to: choice
#           inputs: *non
#     out:
#       actions:
#         - exit_state_machine
class StateMachineBuilder
  class << self
    def run(filename)
      new(filename).build
    end
  end

  # Create a new StateMachineBuilder
  def initialize(filename)
    @filename = filename
  end

  # Build the state machine
  def build
    load
    check_states
    load_necessary_input_for_states
    build_script
  end

  private

  def load
    data = YAML.unsafe_load(File.read(@filename))
    # @type [String]
    @class_name = data['class_name']
    # @type [String, nil]
    @class_doc = data['class_doc']
    # @type [String, nil]
    @parent_class = data['parent_class']
    # @type [Array<String>]
    @includes = data['includes']
    # @type [Hash{ String => String }]
    @inputs = data['inputs']
    # @type [Hash{String => Hash}]
    @states = data['states']
  end

  def check_states
    raise 'Missing init state' unless @states['init']
    raise 'State machine has no transition to sub states' if (@states['init']['transitions'] || []).empty?
  end

  def load_necessary_input_for_states
    @input_per_states = {}
    @states.each do |state_name, data|
      transitions = data['transitions'] || []
      inputs = transitions.reduce([]) { |prev, curr| prev.concat((curr['inputs'] || {}).keys) }
      @input_per_states[state_name] = inputs.uniq
    end
  end

  def build_script
    opening, ending, spaces = guess_script_opening_and_ending
    script = <<~EOSCRIPT
      # Script generated by StateMachineBuilder
      # Generation Date: #{Time.new.strftime('%Y-%m-%d %H:%M:%S')}
      __LINE__.to_i

    EOSCRIPT
    script << opening
    script << initialize_part(spaces)
    script << build_states(spaces)[0..-2]
    script << ending
    File.write(@filename.sub(/\.yml$/, '.rb'), script)
  end

  # @return [Array<String>]
  def guess_script_opening_and_ending
    opening = ''
    ending = ''
    current_module = ::Object
    level = 0
    class_names = @class_name.split('::')
    class_names[0..-2].each do |class_name|
      constant = current_module.const_defined?(class_name.to_sym) ? current_module.const_get(class_name) : Kernel
      if constant.is_a?(Module)
        opening << "#{'  ' * level}module #{class_name}\n"
      else
        opening << "#{'  ' * level}class #{class_name}\n"
      end
      ending.prepend("#{'  ' * level}end\n")
      current_module = constant
      level += 1
    end
    opening << build_doc('  ' * level) if @class_doc
    if @parent_class
      opening << "#{'  ' * level}class #{class_names.last} < #{@parent_class}\n"
    else
      opening << "#{'  ' * level}class #{class_names.last}\n"
    end
    ending.prepend("#{'  ' * level}end\n")

    return opening, ending, '  ' * (level + 1)
  end

  # @param spaces [String]
  def build_doc(spaces)
    @class_doc.split("\n").map { |doc| doc.empty? ? "#{spaces}#\n" : "#{spaces}# #{doc}\n" }.join
  end

  # @param spaces [String]
  def initialize_part(spaces)
    inputs = @inputs.map { |k, v| "#{spaces}  @smi_#{k.downcase} = #{v}\n" }.join
    includes = @includes.map { |i| "#{spaces}include #{i}\n" }.join
    hash_keys = @states.map { |k, _| "#{spaces}  #{k}: :update_#{k}" }.join(",\n")
    <<~EOINITIALIZE
      #{includes}
      #{spaces}# Constant holding all the update method to call depending on the state
      #{spaces}STATE_UPDATE_METHODS = {
      #{hash_keys}
      #{spaces}}

      #{spaces}private

      #{spaces}# Function that initialize the state machine, please, do not forget to call this function where it makes sense (depending on dependencies)
      #{spaces}def initialize_state_machine
      #{inputs}#{spaces}  @sm_state = :init
      #{spaces}end

      #{spaces}# Function that call the right update method, don't forget to call it if you're not inheriting from a class that calls it
      #{spaces}def update_state_machine
      #{spaces}  send(STATE_UPDATE_METHODS[@sm_state])
      #{spaces}end

    EOINITIALIZE
  end

  # @param spaces [String]
  def build_states(spaces)
    @states.map do |state_name, state|
      inputs = build_state_inputs(state_name, spaces)
      transition_function = build_transition(state['transitions'] || [], state_name, spaces)
      transitions = build_transitions(state['transitions'] || [], state_name, spaces)
      actions = (state['actions'] || []).map { |action| "#{spaces}  #{action}\n" }.join

      if inputs.empty?
        <<~EOSTATE
          #{spaces}def update_#{state_name}
          #{actions}#{state['transitions'] ? "#{spaces}  @sm_state = :#{state['transitions'].first['to']}" : "#{spaces}  # This is a dead end."}
          #{spaces}end

        EOSTATE
      else
        <<~EOSTATE
          #{transitions}#{transition_function}
          #{inputs}
          #{spaces}def update_#{state_name}
          #{actions}#{spaces}  update_#{state_name}_inputs
          #{spaces}  update_state_from_#{state_name}
          #{spaces}end

        EOSTATE
      end
    end.join
  end

  def build_state_inputs(state_name, spaces)
    inputs = @input_per_states[state_name].map { |k| "#{spaces}  @smi_#{k.downcase} = #{@inputs[k]}\n" }.join
    return '' if inputs.empty?

    <<~EOINPUTS
      #{spaces}def update_#{state_name}_inputs
      #{inputs}#{spaces}end
    EOINPUTS
  end

  def build_transition(transitions, state_name, spaces)
    transition_code = transitions.map do |transition|
      "#{spaces}  return @sm_state = :#{transition['to']} if tansitioning_from_#{state_name}_to_#{transition['to']}?\n"
    end.join
    <<~EOTRANSITION
      #{spaces}def update_state_from_#{state_name}
      #{transition_code}#{spaces}end
    EOTRANSITION
  end

  def build_transitions(transitions, state_name, spaces)
    transitions.map do |transition|
      <<~EOTRANSITION
        #{spaces}def tansitioning_from_#{state_name}_to_#{transition['to']}?
        #{spaces}  #{build_inputs(transition['inputs'])}
        #{spaces}end

      EOTRANSITION
    end.join
  end

  # @param inputs [Hash]
  def build_inputs(inputs)
    return 'true' if !inputs || inputs.empty?

    return inputs.map { |k, v| "@smi_#{k.downcase} == #{v.inspect}" }.join(' && ')
  end
end
