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

    # The list of all the commands that anyone can do. I think this is going to go away...
    # maybe I'll replace it with a hash from a symbol to a command list, and everyone has 
    # list of lists that they can access commands from.
    GlobalCommands = []

    #look through the command list for a command named n and return it.
    def self.find_command n
      GlobalCommands.find { |c| c.named? n }
    end
  end
end
