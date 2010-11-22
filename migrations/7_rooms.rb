module Mud
  class Room
    attr_reader :name, :description, :players
    def initialize name, description
      @name = name
      @description = description
      @players = []
      @exits = {}
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
      dir = dir.to_sym
      dir = DIRS[dir] if DIRS.key? dir
      dir
    end

    def has_exit? dir
      dir = normalize_direction dir
      @exits.key? dir
    end
    #find the destination for going in a direction
    def dest dir
      dir = normalize_direction dir
      @exits[dir]
    end
    #create an exit
    def dig dir, target
      dir = normalize_direction dir
      @exits[dir] = target
    end
    #remove an exit
    def fill dir
      dir = normalize_direction dir
      @exits.remove(dir)
    end

    def players_string
      @players.map{ |p| p.name }.join(", ")
    end
    def exits_string 
      @exits.keys.map{ |e| e.to_s }.join(", ")
    end

    def echo string, list_of_players_to_avoid = [], color = :off
      (@players - list_of_players_to_avoid).each { |p| p.hear_line string, color }
    end

    def leave_to player, direction
      @players.delete(player)
      echo "#{player.name} leaves to the #{normalize_direction direction}"
      dest direction
    end
    def arrive_from player,direction
      echo "#{player.name} enters from the #{INVERSES[normalize_direction direction]}"
      @players << player
      player.room = self
      player.command "look"
    end
  end
end
