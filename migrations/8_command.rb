module Mud 
  module Commands
    #If a command doesn't override enact, it throws "command not implemented"
    class CommandNotImplementedError < RuntimeError; end

    class Command
      attr_accessor :name
      def initialize name, aliases
        @name = name 
        @aliases = [name] + aliases
      end

      def named?(name)
        @aliases.include? name
      end

      #run this command, as done by this player, with this arg string
      def enact player, args
        raise CommandNotImplementedError.new(self.class.to_s)
      end
      ## this is where other helper methods might go, for parsing arguments and such
      #this Raises a NoBalanceError (which is caught by player.command)
      # if the player is offbalance
      def require_balance player, type = :balance
        raise HasBalance::NoBalanceError.new unless player.on_balance? type
      end

      def process actor, args, types
        l = args.split(" ", types.length+1)
        rtn = []
        types.length.times do |i|
          if types[i].is_a? Symbol
            rtn << self.send(types[i], actor, l[i])
          else
            rtn << self.send(types[i].find{ |j| self.send(j, actor, l[i]) }, actor, l[i])
          end
        end
        rtn
      end

      def room actor, name
        W.rooms[name.to_sym]
      end

      def entity_here actor, name
        p = actor.room.find_player name
        return p if p
        actor.room.find_mobile name
      end

      def mobile_here actor, name
        #return actor.room.mobiles.find{|m| m.is_named? name }
        actor.room.find_mobile name
      end

      def item actor, name
        actor.find_item(name) || actor.room.find_item(name)
      end
      def item_from_inventory actor, name
        actor.find_item name
      end
      def item_from_room actor, name
        actor.room.find_item name
      end
      def player_online actor, name
        return actor if name == "me"
        return W.find_player(name) if W.players.include?(W.find_player(name))
        nil
      end
      def player_here actor, name
        return actor if name == "me"
        #actor.room.players.find { |p| p.is_named? name }
        actor.room.find_player name
      end
      def player actor, name # => player in the game
        return actor if name == "me"
        W.find_player(name) 
      end

    end

    # this is a hash of command lists.
    CommandList = Hash.new { |hash, key| hash[key] = [] }

    #look through the command list for a command named n and return it.
    def self.find_command n, lists = []
      lists = [:global] + lists
      lists.map{ |sym| CommandList[sym] }.find do |l|
        l.find do |c|
          return c if c.named? n
        end
      end
      nil
    end
  end
end
