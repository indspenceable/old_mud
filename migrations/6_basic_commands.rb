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
        player.room.echo "#{player.name} says: \"#{args}\"", [player]
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
        player.hear_line player.room.players.reject{|p| p == player}.map{|p|p.name}.join(", "), :blue
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
  end
end
