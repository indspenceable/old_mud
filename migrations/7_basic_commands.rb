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
        player.room.trigger_reaction :say, player, args
      end
    end
    CommandList[:global] << Say.new

    #look at the current room
    class Look < Command
      def initialize
        super("look",["l"])
      end
      def enact player, args
        if args == ""
          player.hear_line player.room.name, :yellow
          player.hear_line(player.room.description + " ", nil,
                           player.room.players.reject{|p| p == player}.map{|p| p.display_description.capitalize }.join(" ") + " ", :blue,
                           player.room.mobiles.map{ |m| m.display_description.capitalize }.join(" ") + " ", nil,
                           (Mud::list_array player.room.items.map{|i| i.long_display_string}) + " ", nil)
          player.hear_line(player.room.exits_string, :yellow)
        else
          target, = process player, args, [[:player_here, :item]]
          if target
            player.hear_line "That is here."
          else
            player.hear_line "You can't see anything by that name."
          end
        end
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
        existing_room, = process player, args, [:room]
        unless existing_room  
          args = args.split(" ")
          room_name = args[0].downcase.to_sym
          W.add_room(Room.new(room_name, "Title", "A generic area."))
          player.hear_line "You have built room [#{room_name}]."
        else
          player.hear_line "There already exists a room by that name..."
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
        return player.hear_line "You must enter a direction to dig in." unless args[0]
        return player.hear_line "You must designate the destination." unless args[1]
        return player.hear_line "There is no room with that name!" unless W.rooms[args[1].to_sym]
        player.room.dig args[0], args[1].to_sym
        player.hear_line "You succesfully dig."
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
        target_room, = process player, args, [:room]
        if target_room
          if target_room == player.room
            player.hear_line "You are alredy in that room..."
          else
            player.room.echo "#{player.display_name} suddenly dissapears.", [player]
            player.hear_line "You vanish suddenly, and appear somewhere new..."
            player.room.remove_player player
            player.room = target_room
            player.room.add_player player
            player.room.echo "#{player.display_name} suddenly materializes.", [player]
            player.command "look";
          end
        else
          player.hear_line "There is no room by that name."
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
        require_balance player
        player.unbalance_for :balance, 500
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
        player.hear_line Mud::list_array(player.items.map{|i| i.short_display_string}, "You are carrying nothing.").capitalize
      end
    end
    CommandList[:global] << Inventory.new

    class Examine < Command
      def initialize
        super "examine", ["probe","check"]
      end
      def enact player, args
        looking_at, = process player, args, [[:player_here, :item]]
        return player.hear_line "yes, that is here." if looking_at
        player.hear_line "No that is not here."
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
        require_balance player
        to_drop, = process player, args, [:item_from_inventory]
        if to_drop
          to_drop.move_to player.room
          player.room.echo "#{player.display_name} drops #{to_drop.short_display_string}", [player]
          player.hear_line "You drop #{to_drop.short_display_string}"
        else
          player.hear_line "You don't have that."
        end
      end
    end
    CommandList[:global] << Drop.new

    class Get < Command
      def initialize
        super "get", ["take"]
      end
      def enact player, args
        require_balance player
        to_get, = process player, args, [:item_from_room]
        if to_get
          to_get.move_to player
          player.room.echo "#{player.display_name} gets #{to_get.short_display_string}", [player]
          player.hear_line "You get #{to_get.short_display_string}"
        else
          player.hear_line "You don't see that."
        end
      end
    end
    CommandList[:global] << Get.new

    class Move < Command
      def initialize
        super("move", ["take"])
      end
      def enact player, args
        require_balance player
        args = args.split(' ')
        return player.room.leave_to(player,args[0]).arrive_from(player,args[0]) if player.room.has_exit?(args[0])
        player.hear_line "You can't go in that direction!"
      end
    end
    CommandList[:global] << Move.new

    class Wield < Command
      def initialize
        super("wield", [])
      end
      def enact player, args
        require_balance player
        to_wield, = process player, args, [:item_from_inventory]
        if to_wield
          player.set_item :weapon, to_wield
          player.room.echo "#{player.display_name} wields #{to_wield.short_display_string}.", [player]
          player.hear_line "You begin to wield #{to_wield.short_display_string}"
        else
          player.hear_line "You don't have that."
        end
      end
    end
    CommandList[:global] << Wield.new

    class Swing < Command
      def initialize
        super("swing", [])
      end
      def enact player, args
        if (w = player.item_for :weapon)
          target, = process player, args, [:player_here]
          if target
            return player.hear_line "You can't attack yourself!" if target == player
            power =(w.respond_to?(:weapon_power)? w.weapon_power : 3)
            target.take_damage power, player.sym, :swords, "#{player.display_name} swings #{w.short_display_string} at you visciously."
            player.room.echo "#{player.display_name} swings #{w.short_display_string} at #{target.display_name} visciously.", [player, target]
            player.hear_line "You swing #{w.short_display_string} at #{target.display_name} visciously."
          else
            player.hear_line "Swing at what?"
          end
        else
          player.hear_line "You need a weapon equipped to do that!"
        end
      end
    end
    CommandList[:global] << Swing.new

  end
end
