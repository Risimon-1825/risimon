module PFM
  # InGame Bag management
  #
  # The global Bag object is stored in $bag and PFM.game_state.bag
  # @author Nuri Yuri
  class Bag
    # Last socket used in the bag
    # @return [Integer]
    attr_accessor :last_socket
    # Last index in the socket
    # @return [Integer]
    attr_accessor :last_index
    # If the bag is locked (and react as being empty)
    # @return [Boolean]
    attr_accessor :locked
    # Set the last battle item
    # @return [Integer]
    attr_accessor :last_battle_item_id
    # Tell if the bag is alpha sorted
    # @return [Boolean]
    attr_accessor :alpha_sorted
    # Get the game state responsive of the whole game state
    # @return [PFM::GameState]
    attr_accessor :game_state

    # Number of shortcut
    SHORTCUT_AMOUNT = 4
    # Create a new Bag
    # @param game_state [PFM::GameState] variable responsive of containing the whole game state for easier access
    def initialize(game_state = PFM.game_state)
      self.game_state = game_state
      @items = Array.new(each_data_item.to_a.size, 0)
      @orders = [[], [], [], [], [], [], []]
      @last_socket = 1
      @last_index = 0
      @shortcut = Array.new(SHORTCUT_AMOUNT, 0)
      @locked = false
      @last_battle_item_id = 0
      @alpha_sorted = false
    end

    # If the bag contain a specific item
    # @param id [Integer, Symbol] id of the item in the database
    # @return [Boolean]
    def contain_item?(id)
      return item_quantity(id) > 0
    end
    alias has_item? contain_item?

    # Tell if the bag is empty
    # @return [Boolean]
    def empty?
      return @items.all?(&:zero?)
    end

    # The quantity of an item in the bag
    # @param id [Integer, Symbol] id of the item in the database
    # @return [Integer]
    def item_quantity(id)
      return 0 if @locked

      return @items[data_item(id).id] || 0
    end

    # Add items in the bag and trigger the right quest objective
    # @param id [Integer, Symbol] id of the item in the database
    # @param nb [Integer] number of item to add
    def add_item(id, nb = 1)
      return if @locked
      return remove_item(id, -nb) if nb < 0

      id = data_item(id).id
      @items[id] ||= 0
      @items[id] += nb
      add_item_to_order(id)
      game_state.quests.add_item(id)
    end
    alias store_item add_item

    # Remove items from the bag
    # @param id [Integer, Symbol] id of the item in the database
    # @param nb [Integer] number of item to remove
    def remove_item(id, nb = 999)
      return if @locked
      return add_item(id, -nb) if nb < 0

      id = data_item(id).id
      @items[id] ||= 0 unless @items[id]
      @items[id] -= nb
      if @items[id] <= 0
        @items[id] = 0
        remove_item_from_order(id)
      end
    end
    alias drop_item remove_item

    # Get the order of items in a socket
    # @param socket [Integer, Symbol] ID of the socket
    # @return [Array]
    def get_order(socket)
      return [] if @locked
      return @shortcut if socket == :favorites
      return process_battle_order(socket) if socket.is_a?(Symbol) # TODO

      return (@orders[socket] ||= [])
    end

    # Reset the order of items in a socket
    # @param socket [Integer] ID of the socket
    # @return [Array] the new order
    def reset_order(socket)
      arr = get_order(socket)
      unless socket == :favorites
        arr.clear
        arr.concat(@items.each_index.select { |item_id| data_item(item_id).socket == socket && (@items[item_id] || 0) > 0 })
      end
      unless each_data_item.select { |item| item.socket == socket }.all? { |item| item.position.zero? }
        arr.sort! { |item_ida, item_idb| data_item(item_idb).position <=> data_item(item_ida).position }
      end
      @alpha_sorted = false
      return arr
    end
    alias sort_ids reset_order

    # Sort the item of a socket by their names
    # @param socket [Integer] ID of the socket
    # @param reverse [Boolean] if we want to sort reverse
    def sort_alpha(socket, reverse = false)
      if reverse
        reset_order(socket).sort! { |item_ida, item_idb| data_item(item_idb).name <=> data_item(item_ida).name }
        @alpha_sorted = false
      else
        reset_order(socket).sort! { |item_ida, item_idb| data_item(item_ida).name <=> data_item(item_idb).name }
        @alpha_sorted = true
      end
    end

    # Define a shortcut
    # @param index [Integer] index of the item in the shortcut
    # @param id [Integer, Symbol] id of the item in the database
    def set_shortcut(index, id)
      @shortcut ||= Array.new(SHORTCUT_AMOUNT, 0)
      @shortcut[index % SHORTCUT_AMOUNT] = data_item(id).id
    end

    # Get the shortcuts
    # @return [Array<Integer>]
    def shortcuts
      @shortcut ||= Array.new(SHORTCUT_AMOUNT, 0)
      return @shortcut
    end
    alias get_shortcuts shortcuts

    # Get the last battle item
    # @return [GameData::Item]
    def last_battle_item
      data_item(@last_battle_item_id || 0)
    end

    private

    # Make sure the item is in the order, if not add it
    # @param id [Integer] ID of the item
    def add_item_to_order(id)
      return if @items[id] <= 0

      socket = data_item(id).socket
      get_order(socket) << id unless get_order(socket).include?(id)
    end

    # Make sure the item is not in the order anymore
    # @param id [Integer] ID of the item
    def remove_item_from_order(id)
      return unless @items[id] <= 0

      get_order(data_item(id).socket).delete(id)
    end
  end

  class GameState
    # The bag of the player
    # @return [PFM::Bag]
    attr_accessor :bag

    on_initialize(:bag) { @bag = PFM.bag_class.new(self) }
    on_expand_global_variables(:bag) do
      # Variable containing the player's bag information
      $bag = @bag
      $bag.game_state = self
    end
  end
end

PFM.bag_class = PFM::Bag
