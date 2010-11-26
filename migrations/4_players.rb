module Mud
  class Player
    attr_accessor :connection, :hashed_password, :command_groups

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

    # create a new player. This should ONLY be called when a player is CREATED, not logged in.
    def initialize name,hashed_password
      @name = name.downcase
      @commands = []
      @hashed_password = hashed_password

      @pending_output = ""

      W.master_players[sym] = self
      self.room = W.default_room
      @command_groups = []
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

    # Hear is the method for producing output.
    def hear_line data, color_attr = []
      if data.strip != ""
        color_attr = [color_attr] if color_attr.is_a? Symbol
        @pending_output += color_attr.map{|a| COLORMAP[a]}.join('')+data+COLORMAP[:off] + "\n"
      end
    end

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
      command_name,args = data.split(' ', 2)
      # if args is nil, lets make it a string.
      args ||= ""

      
      if com = Commands::find_command(command_name, @command_groups) 
        com.enact(self, args)
      elsif room.has_exit?(command_name)
        room.leave_to(self,command_name).arrive_from(self,command_name)
      else
        if (Room::DIRS.keys + Room::DIRS.values).include? command_name.to_sym
          hear_line "You can't go that direction!", :red
        else
          hear_line "You can't do that!"
        end
      end
    end

    #generates the proper prompt string
    def prompt
      "> "
    end

    #this allows simultanious output to be batched together in the same package.
    def flush_output
      if @pending_output != ""
        @pending_output += prompt
        connection.send_data @pending_output
        clear_output
      end
    end

    def clear_output
      @pending_output = "" 
    end
  end
end
