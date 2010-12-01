module Mud
  class Room
    attr_reader :sym
    attr_accessor :name, :description

    include HasInventory
    #players
    def players
      @players.map{|n| W.find_player(n) }.freeze
    end
    def add_player p
      @players << p.sym
    end
    def remove_player p
      @players.delete(p.sym)
    end

    def mobiles
      @mobiles.map{|id| W.mobiles[id]}.freeze
    end
    def add_mobile m
      @mobiles << m.id
    end
    def remove_mobile m
      @mobiles.delete m.id
    end

    def initialize symbol, name, description
      @sym = symbol
      @name = name
      @description = description
      @players = []
      @mobiles = []
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
      @exits.remove(dir)
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

    def echo string, list_of_players_to_avoid = [], color = :off
      (self.players - list_of_players_to_avoid).each { |p| p.hear_line string, color }
    end
    
    def trigger_reaction reaction_type, actor, *args
      method = ("react_to_" + reaction_type.to_s).to_sym
      mobiles.each do |m|
        puts "MOBILE #{m}"
        puts "method is #{method} and m reacts? #{m.respond_to? method}"
        m.send(method, actor, *args) if m.respond_to? method
      end
    end

    def leave_to player, direction
      remove_player player if player.is_a? Player
      remove_mobile player if player.is_a? Mobile
      echo "#{player.display_name} leaves to the #{normalize_direction direction}"
      dest direction
    end

    def arrive_from player,direction
      echo "#{player.display_name} enters from the #{INVERSES[normalize_direction direction]}"
      add_mobile player if player.is_a? Mobile
      if player.is_a? Player
        add_player player 
        player.room = self
        player.command "look"
      end
    end
  end
end
