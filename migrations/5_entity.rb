module Mud
  module Entities
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
  end
end
