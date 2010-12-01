module Mud
  class Room
    attr_reader :sym
    attr_accessor :name, :description

    include HasInventory
    include Entities::HasPlayers
    include Entities::HasMobiles

    def initialize symbol, name, description
      @sym = symbol
      @name = name
      @description = description
      @exits = {}
    end

    def on_load
      @players.clear
    end

    DIRS = { 
      :n => :north,
      :s => :south,
      :e => :east,
      :w => :west,
      :nw => :northwest,
      :sw => :southwest,
      :ne => :northeast,
      :se => :southeast,
      :u => :up,
      :d => :down 
    }
    INVERSES = {
      :north => :south,
      :east => :west,
      :up => :down,
      :northeast => :southwest,
      :southeast => :northwest
    }
    INVERSES.dup.each_pair do |k,v|
      INVERSES[v] = k
    end

    def normalize_direction dir
      nil unless dir
      dir = dir.to_sym
      dir = DIRS[dir] if DIRS.key? dir
      dir
    end

    def has_exit? dir
      return false unless dir
      dir = normalize_direction dir
      @exits.key? dir
    end

    #find the destination for going in a direction
    def dest dir
      dir = normalize_direction dir
      W.rooms[@exits[dir]]
    end

    #create an exit
    def dig dir, target
      dir = normalize_direction dir
      @exits[dir] = target
    end

    #remove an exit
    def fill dir
      dir = normalize_direction dir
      @exits.delete(dir)
    end

    def exits_string
      case
      when @exits.size == 0
        "There are no exits."
      when @exits.size == 1
        return "You see an exit to the #{@exits.keys[0]}."
      else
        keys = @exits.keys
        "You see exits to the #{keys.first(keys.size-1).join(", ")} and #{keys.last}."
      end
    end

    

    def leave_to target, direction
      new_room = dest direction
      echo "#{target.display_name} leaves to the #{normalize_direction direction}", [target]
      target.move_to new_room
      new_room.echo "#{target.display_name} enters from the #{INVERSES[normalize_direction direction]}", [target]
    end
  end
end
