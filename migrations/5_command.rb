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
