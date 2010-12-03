module Mud
  module Entities
    module HasPlayers
      #find a player by its identification.
      def find_player name
        players.find{|p| p.is_named? name}
      end

      #retrieving the items from this character
      def players
        (@players ||= []).map{|id| W.find_player id}.freeze
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
        hear_line("#{hp}/#{max_hp} ", [hp_color], 
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
  end
end
