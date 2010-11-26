module Mud
  module Commands
    #Generate a list of commands that this player can do.
    class Help < Command
      def initialize
        super("help",["h","?"])
      end
      def enact player, args
        player.hear_line 'Help System', :blue 
        player.hear_line "You have access to the following commands:"
        ([:global] + player.command_groups).each do |l|
          CommandList[l].each do |c|
            player.hear_line "\t#{c.name}", :red
          end
        end
      end
    end
    CommandList[:global] << Help.new

    # Run the migrations on the server. This is an admin command.
    class Migrate < Command
      def initialize
        super('migrate',[])
      end
      def enact player, args
        player.hear_line "Migration starting..."
        Migrator.migrate
        player.hear_line "Migration completed."
      end
    end
    CommandList[:admin] << Migrate.new

    #echo a string to the players room
    class Say < Command
      def initialize
        #Say has a special case
        super("say", [])
      end
      def enact player, args
        player.room.echo "#{player.display_name} says: \"#{args}\"", [player]
        player.hear_line "You say: \"#{args}\""
      end
    end
    CommandList[:global] << Say.new

    #look at the current room
    class Look < Command
      def initialize
        super("look",["l"])
      end
      def enact player, args
        player.hear_line player.room.name, :yellow
        player.hear_line player.room.description
        player.hear_line player.room.players.reject{|p| p == player}.map{|p| p.display_name }.join(", "), :blue
        player.hear_line player.room.exits_string, :yellow
      end
    end
    CommandList[:global] << Look.new

    #save the gamestate. This is an admin command
    class Save < Command
      def initialize
        super("save", [])
      end
      def enact player, args
        player.hear_line "You saved the game."
        W.dump_state
      end
    end
    CommandList[:admin] << Save.new

    class Quit < Command
      def initialize
        super("quit",["qq"])
      end
      def enact player, args
        player.connection.close_connection
      end
    end
    CommandList[:global] << Quit.new


    class Shutdown < Command
      def initialize
        super("shutdown",[])
      end
      def enact player, args
        EventMachine::stop_event_loop
      end
    end
    CommandList[:admin] << Shutdown.new

    class Dig < Command
      def initialize
        super("dig", [])
      end
      def enact player, args
        args = args.split(" ",-2) 
        begin
          raise "You must enter the name of the new room!" unless args[0]
          W.add_room(Room.new(args[0].to_sym, "Title", "A generic area."))
        rescue RuntimeError => e
          player.hear_line e.to_s, :red
        end
      end
    end
    CommandList[:builder] << Dig.new

    class Shout < Command
      def initialize
        super("shout", [])
      end
      def enact player, args
        W.each_room do |r|
          r.echo "#{player.display_name} shouts: \"#{args}\"", [player], :red
        end
        player.hear_line "You shout: \"#{args}\"", :red
      end
    end
    CommandList[:global] << Shout.new

    class Who < Command
      def initialize
        super("who", [])
      end
      def enact player, args
        player.hear_line "Players online: "
        W.players.each do |p|
          player.hear_line "\t#{p.name}"
        end
      end
    end
    CommandList[:global] << Who.new

    class Goto < Command
      def initialize
        super("goto", [])
      end
      def enact player, args
        r_name = args.downcase.to_sym
        if !W.rooms[r_name]
          player.hear_line "There is no room by that name."
        elsif W.rooms[r_name] == player.room
          player.hear_line "You are alredy in that room..."
        else
          player.room.echo "#{player.display_name} suddenly dissapears.", [player]
          player.hear_line "You vanish suddenly, and appear somewhere new..."
          player.room.remove_player player
          player.room = W.rooms[r_name]
          player.room.add_player player
          player.room.echo "#{player.display_name} suddenly materializes.", [player]
          player.command "look";
        end
      end
    end
    CommandList[:admin] << Goto.new
  end
end
