module Mud
  COLORMAP = {
    :off => "\033[0m",
    :bold => "\033[1m",
    :red => "\033[31m",
    :green => "\033[32m",
    :yellow => "\033[33m",
    :blue => "\033[34m"
  }
  module HasRoom
    #accessor
    def room
      W.rooms[@room]
    end
    #setter
    def room= r
      @room = r.sym
    end

    def move_to new_room
      raise "Need to define move_to"
    end

  end

  module DoesCommands
    # This error is raised if you don't have balance and try to do a move that requires balance
    class NoBalanceError < Exception; end
    # Run a command. Takes an unparsed string. The command knows if its 
    # being run directly from input or as the result of something else
    # (like, moving invokes player.command "look")
    def command data, command_groups=[:global], from_input=false
      data.strip!
      return unless data != ""
      command_name,args = data.split(' ', 2)
      # if args is nil, lets make it a string.
      args ||= ""

      # either - is there a command?
      # or, there is an exit in this room/a standard exit by that name.
      # elsewise, "you can't do that."
      begin
        if com = Commands::find_command(command_name, command_groups) 
          com.enact(self, args)
        elsif room.has_exit?(command_name)|| (Room::DIRS.keys + Room::DIRS.values).include?(command_name.to_sym)
          Commands::find_command("move", [:global]).enact(self,data)
          #room.leave_to(self,command_name).arrive_from(self,command_name)
        else
          hear_line "You can't do that!"
        end
      rescue NoBalanceError => e
        hear_line "You can't do that off balance."
      rescue Exception => e
        hear_line "You've triggered an uncaught exception. Please report this to the mud...."
        puts "There has been an uncaught exception, triggered by #{display_name} trying to do a command with #{data}"
        puts "It raised #{e} at"
        puts e.backtrace
      end
    end
  end
  module HasBalance
    # set this player to be unbalanced on a specific type of balance for 
    # t ticks.
    def unbalance_for balance_type, t
      @off_balance_timer[balance_type] = (@off_balance_timer[balance_type] || 0) + t
    end

    # decrease balances by dt
    def update_balance dt
      @off_balance_timer.keys.each do |k|
        if @off_balance_timer[k] && (@off_balance_timer[k] -= dt) <= 0
          hear_line "You have regained #{k.to_s}"
          @off_balance_timer[k] = nil
        end
      end
    end

    # returns if we have balance on that type of balance
    def on_balance? balance_type
      return !@off_balance_timer.values.find{|v| v} if balance_type == :all
      !@off_balance_timer[balance_type]
    end
  end
  module HasHealth
    attr_accessor :hp, :max_hp
    #take damage, and show this message to show that.
    def take_damage amt, name, sym, message
      @hp -= amt
      @last_hit_by = name
      @kill_type = sym
      hear_line message
      # check if you died?
    end
  end
  module HasMana
    attr_accessor :mp, :max_mp
  end

  class Entity
    include DoesCommands
    include HasRoom
    include HasBalance
    include HasHealth
    include HasMana
    include HasInventory
  end

  module HasPlayers
    #retrieving the items from this character
    def find_player p
      players.find{|cp| p == cp}
    end
    def players
      (@players ||= []).map{|id| puts "ID IS #{id}"; W.find_player id}.freeze
    end

    #moving players around.
    #let players do this
    def remove_player p
      (@players ||= []).delete p.sym
    end
    def add_player p
      @players << p.sym unless (@players ||= []).include? p.sym
    end

    #echo
    def echo string, list_of_players_to_avoid = [], color = :off
      (self.players - list_of_players_to_avoid).each { |p| p.hear_line string, color }
    end
  end

  # A mapping of color symbols to their escape sequences.
  class Player < Entity
    attr_accessor :hashed_password, :command_groups

    # we don't need this, but it needs to be able to do this just in case.
    def react_to *args; end

    def move_to new_room
      self.room.remove_player self
      self.room = new_room 
      new_room.add_player self
    end

    #the truename of this player
    def sym
      @name.to_sym
    end

    #the name that this player is usually displayed by.
    # takes into account their wielding, blah blah blah
    def display_name
      @name.capitalize.freeze
    end

    #this is what they look like in a "look"
    def display_description
      @name.capitalize + " stands here" + ((item_for :weapon) ? (", wielding " + item_for(:weapon).short_display_string) : "") + "."
    end

    # returns if this paleyr is named this string
    # it also can take care of other cases?
    def is_named? n
      n && n.downcase == @name
    end

    def connection
      W.player_connection_map[self]
    end
    def connection= c
      W.player_connection_map[self] = c
    end

    # create a new player. This should ONLY be called when a player is CREATED, not logged in.
    def initialize name,hashed_password
      @name = name.downcase
      @commands = []
      @hashed_password = hashed_password

      @pending_output = ""

      W.create_player(self)
      self.room = W.default_room
      @command_groups = []

      self.max_hp = 100
      self.max_mp = 100
      self.hp= max_hp
      self.mp= max_mp


      @off_balance_timer = {}
    end

    # when you load the player back into the game from a serialized state, here are some things we
    # need to fix.
    def on_load
      clear_output
    end

    # When a player logs into the mud, show some default messages, and add them to the room they
    # are currently located in. Also, add itself to th list of active players
    def login
      room.add_player self
      room.echo("#{display_name} suddenly appears.", [self], :blue)
      hear_line("You fade in to being...", :blue)
      W.players << self
    end
    #inverse of login
    def logout
      room.remove_player self
      room.echo("#{display_name} dissapears.", [self], :blue)
      hear_line("You fade out of being...", :blue)
      W.players.delete(self)
    end

    #hear something - message, color, message, color
    # this is all followed by a new line
    def hear_line *args
      raise "must give arguments" if args.size == 0
      args << nil if (args.size%2) ==  1
      hear *args
      @pending_output += "\n\r"
    end
    #hear something - message, color, message, color
    def hear *args
      raise "must give arguments" if args.size == 0
      args << nil if (args.size%2) ==  1
      (args.size/2).times do |off|
        add_output(args[2*off], args[2*off+1])
      end
    end
    private :hear
    # Hear is the method for producing output.
    def add_output data, color_attr = nil
      color_attr ||= []
      if data.strip != ""
        color_attr = [color_attr] if color_attr.is_a? Symbol
        @pending_output += color_attr.map{|a| COLORMAP[a]}.join('')+data+COLORMAP[:off]
      end
    end
    private :add_output

    # When a player gets input, it might have a shortcut for say.
    # this method will replace a leading ' or " with 'say '
    def preprocess_data data
      if data[0] == "'" || data[0] == '"'
        "say " + data[1,data.length]
      else
        data
      end
    end

    # When we receive input, do the command with processed version of that
    # data
    def receive_data data
      command preprocess_data(data), @command_groups, true
    end

    #generates a prompt string.
    #adds it via hearline
    def add_prompt
      hp_percent = 100*hp/max_hp
      mp_percent = 100*mp/max_mp
      hp_color = case
                 when hp_percent > 66
                   :green
                 when hp_percent > 33
                   :yellow
                 else
                   :red
                 end
      mp_color = case
                 when mp_percent > 66
                   :green
                 when mp_percent > 33
                   :yellow
                 else
                   :red
                 end
      hear("#{hp}/#{max_hp} ", [hp_color], 
           "#{mp}/#{max_mp}", [mp_color], 
           " #{on_balance?(:balance) ? "x" : " "}#{on_balance?(:equilibrium) ? "e" : " "}-", nil)
    end

    #this allows simultanious output to be batched together in the same package.
    def flush_output
      if @pending_output != ""
        add_prompt
        connection.send_data @pending_output
        clear_output
      end
    end

    #remove all output
    def clear_output
      @pending_output = "" 
    end

    # all the things that should be happening constantly
    def tick dt
      update_balance dt
      flush_output
    end
  end


  module HasMobiles
    #retrieving the items from this character
    def find_mobile p
      mobiles.find{|cp| p == cp}
    end
    def mobiles
      (@mobiles ||= []).map{|id| W.mobiles[id]}.freeze
    end

    #moving players around.
    #let players do this
    def remove_mobile p
      (@mobiles ||= []).delete p.sym
    end
    def add_mobile p
      @mobiles << p.sym unless (@mobiles ||= []).include? p.sym
    end

    #trigger reactions
    def trigger_reaction reaction_type, actor, *args
      mobiles.each do |m|
        m.react_to(reaction_type, actor, *args)
      end
    end
  end

  # A mapping of color symbols to their escape sequences.

  class Mobile < Entity
    attr_reader :id
    def initialize
      @@total_items ||= 0
      @@blank_ids ||= []
      @id = @@blank_ids.pop
      @id ||= (@@total_items += 1)

      @off_balance_timer = {}
    end
    def sym
      @id
    end
    def move_to new_room
      self.room.remove_mobile self
      self.room = new_room 
      new_room.add_mobile self
    end
    def hear_line *args; end
    def react_to reaction_type, actor, *args
      method = ("react_to_" + reaction_type.to_s).to_sym
      send(method, actor, *args) if respond_to? method
    end
  end
  class Guy < Mobile
    def initialize r
      super()
      self.room = r
      room.add_mobile self
      W.mobiles[@id] = self

      my_sword = Sword.new(self)
      self.set_item :weapon, my_sword

      @hp = 30
      @max_hp = 30

      @hostile = {}
    end
    def is_named? n
      n == "guy"
    end
    def display_description
      "a guys is standing here, looking nonchalant."
    end
    def display_name
      "an unassuming guy"
    end
    def react_to_say actor, args
      command("say Hello, world!") if args =~ /[Hh]ello/ && actor.is_a?(Player)
    end
    def react_to_attack actor
      command("say My word! You will die for your insolence!") unless hostile?
      @hostile[actor.sym] = 3000
    end
    def hostile?
      @hostile.size > 0
    end
    def update_hostility dt
      @hostile.each_pair do |k,v|
        @hostile[k] = v-dt
      end
      @hostile.reject! { |k,v| v <=0 }
    end

    def tick dt
      update_balance dt
      update_hostility dt
      #get the person they are most hostile to
      if @hostile.size > 0 && on_balance?(:all)
        target = @hostile.to_a.sort{|l,r| r[1] <=> l[1]}[0][0]
        command("say hyaah!")
        command("swing #{target}")
      end
    end
  end
end
