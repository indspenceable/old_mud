module Mud
  module Errors
    class NoBalanceError < Exception
    end
  end
  class Player
    attr_accessor :hashed_password, :command_groups
    attr_accessor :hp, :mp, :max_hp, :max_mp
    include HasInventory

    #accessor
    def room
      W.rooms[@room]
    end

    #setter
    def room= r
      @room = r.sym
    end

    def sym
      @name.to_sym
    end
    def display_name
      @name.capitalize.freeze
    end
    def display_description
      @name.capitalize + ((item_for :weapon) ? (", wielding " + item_for(:weapon).short_display_string) : "") + "."
    end
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

    # A mapping of color symbols to their escape sequences.
    COLORMAP = {
      :off => "\033[0m",
      :bold => "\033[1m",
      :red => "\033[31m",
      :green => "\033[32m",
      :yellow => "\033[33m",
      :blue => "\033[34m"
    }

    def hear_line *args
      raise "must give arguments" if args.size == 0
      args << nil if (args.size%2) ==  1
      hear *args
      @pending_output += "\n\r"
    end

    def hear *args
      raise "must give arguments" if args.size == 0
      args << nil if (args.size%2) ==  1
      (args.size/2).times do |off|
        add_output(args[2*off], args[2*off+1])
      end
    end

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

    # When we receive input, do the command with processed version of that data
    def receive_data data
      command preprocess_data(data), true
    end

    # Run a command. Takes an unparsed string. The command knows if its being run directly from input or
    # as the result of something else (like, moving invokes player.command "look")
    def command data, from_input=false
      data.strip!
      return unless data != ""
      command_name,args = data.split(' ', 2)
      # if args is nil, lets make it a string.
      args ||= ""
      
      # either - is there a command?
      # or, there is an exit in this room/a standard exit by that name.
      # elsewise, "you can't do that."
      begin
        if com = Commands::find_command(command_name, @command_groups) 
          com.enact(self, args)
        elsif room.has_exit?(command_name)|| (Room::DIRS.keys + Room::DIRS.values).include?(command_name.to_sym)
          Commands::find_command("move", @command_groups).enact(self,data)
          #room.leave_to(self,command_name).arrive_from(self,command_name)
        else
          hear_line "You can't do that!"
        end
      rescue Errors::NoBalanceError => e
        hear_line "You can't do that off balance."
      rescue Exception => e
        hear_line "You've triggered an uncaught exception. Please report this to the mud...."
        puts "There has been an uncaught exception, triggered by #{display_name} trying to do a command with #{data}"
        puts "It raised #{e} at"
        puts e.backtrace
      end
    end

    def unbalance_for balance_type, t
      @off_balance_timer[balance_type] = (@off_balance_timer[balance_type] || 0) + t
    end
    def update_balance dt
      @off_balance_timer.keys.each do |k|
        if @off_balance_timer[k] && (@off_balance_timer[k] -= dt) <= 0
          hear_line "You have regained #{k.to_s}"
          @off_balance_timer[k] = nil
        end
      end
    end
    def on_balance? balance_type
      !@off_balance_timer[balance_type]
    end

    def take_damage amt, name, sym
      @hp -= amt
      @last_hit_by = name
      @kill_type = sym
      # check if you died?
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

    def clear_output
      @pending_output = "" 
    end

    def tick dt
      update_balance dt
      flush_output
    end

  end
end
