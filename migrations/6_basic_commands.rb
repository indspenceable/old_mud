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
        player.hear_line(player.room.description + " ", nil,
                         player.room.players.reject{|p| p == player}.map{|p| p.display_name }.join(", ") + " ", :blue,
                         (Mud::list_array player.room.items.map{|i| i.display_string}) + " ", nil)
        player.hear_line(player.room.exits_string, :yellow)
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
        player.disconnect
      end
    end
    CommandList[:admin] << Shutdown.new

    class Build < Command
      def initialize
        super("build", [])
      end
      def enact player, args
        args = args.split(" ")
        begin
          raise "You must enter the name of the new room!" unless args[0]
          room_name = args[0].downcase.to_sym
          W.add_room(Room.new(room_name, "Title", "A generic area."))
          player.hear_line "You have built room [#{room_name}]."
        rescue RuntimeError => e
          player.hear_line e.to_s, :red
        end
      end
    end
    CommandList[:builder] << Build.new

    class Dig < Command
      def initialize
        super("dig", [])
      end
      def enact player, args
        args = args.split(" ")
        begin
          raise "You must enter a direction to dig in." unless args[0]
          raise "You must designate the destination." unless args[1]
          raise "There is no room with that name!" unless W.rooms[args[1].to_sym]
          player.room.dig args[0], args[1].to_sym
          player.hear_line "You succesfully dig."
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
          player.hear_line "\t#{p.display_name}"
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

    class Describe < Command
      def initialize
        super("describe", [])
      end
      def enact player, args
        args = args.split(" ", 2)
        case
        when args.size != 2
          player.hear_line "You must specify name or description, and then give the text for that quality."
        when args[0] == "name"
          player.room.name = args[1]
          player.room.echo "In a flash of lights, your surroundings have transformed."
        when args[0] == "description"
          player.room.description = args[1] if args[0] == "description"
          player.room.echo "In a flash of lights, your surroundings have transformed."
        else
          player.hear_line "You must describe the name or the description."
        end
      end
    end
    CommandList[:builder] << Describe.new

    class Emote < Command
      def initialize
        super 'emote', []
      end
      def enact player, args
        player.room.echo "#{player.display_name} #{args}", [player]
        player.hear_line "You #{args}"
      end
    end
    CommandList[:global] << Emote.new


    class Score < Command
      def initialize
        super 'score', ['sc','status','stat']
      end
      def enact player, args
        player.hear_line "#{player.display_name}"
        hp_percent = player.hp.to_f/player.max_hp
        player.hear_line "#{player.hp}/#{player.max_hp} hp", case
        when hp_percent > 0.66
          :green
        when hp_percent > 0.33
          :yello
        else
          :red
        end
        player.hear_line "#{player.mp}/#{player.max_mp} mp"
      end
    end
    CommandList[:global] << Score.new

    #this is a temporary command
    class DamageSelf < Command
      def initialize
        super "damage", []
      end
      def enact player, args
        args = args.split(" ")
        begin
          case
          when args[0] == "hp"
            player.hp -= args[1].to_i
          when args[0] = "mp"
            player.mp -= args[1].to_i
          else
            raise "Invalid argument"
          end
          player.hear_line "You damaged yourself, jerk."
        rescue
          player.hear_line "Error raised.", :red
        end
      end
    end
    CommandList[:global] << DamageSelf.new

    class Inventory < Command
      def initialize
        super "inventory", ["inv", "i", "ii"]
      end
      def enact player, args
        player.hear_line Mud::list_array(player.items.map{|i| i.display_string}, "You are carrying nothing.")
      end
    end
    CommandList[:global] << Inventory.new

    class Examine < Command
      def initialize
        super "examine", ["probe","check"]
      end
      def enact player, args
        args = args.split(' ')
        return player.hear_line "What do you want to look at?" unless args.size > 0
        player.hear_line "Yeah, mostly unimplemented."
      end
    end
    CommandList[:global] << Examine.new

    class RoomList < Command
      def initialize
        super "roomlist", ["rl"]
      end
      def enact player, args
        player.hear_line "Room list:"
        W.rooms.each_pair do |k,v|
          player.hear_line "\t#{k.to_s}"
        end
      end
    end
    CommandList[:admin] << RoomList.new

    class Drop < Command
      def initialize
        super "drop", []
      end
      def enact player, args
        args = args.split(" ")
        if (i = player.find_item args[0])
          i.move_to player.room
          player.room.echo "#{player.display_name} drops #{i.display_string}", [player]
          player.hear_line "You drop #{i.display_string}"
        else
          player.hear_line "You don't see anything called that."
        end
      end
    end
    CommandList[:global] << Drop.new

    class Get < Command
      def initialize
        super "get", ["take"]
      end
      def enact player, args
        args = args.split(" ")
        if (i = player.room.find_item args[0])
          i.move_to player
          player.room.echo "#{player.display_name} takes #{i.display_string}", [player]
          player.hear_line "You take #{i.display_string}"
        else
          player.hear_line "You don't see anything called that."
        end
      end
    end
    CommandList[:global] << Get.new
  end
end
