module Mud
  module Commands
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
      def enact player, args
        raise CommandNotImplementedError.new(self.class.to_s)
      end
    end

    GlobalCommands = []
    def self.find_command n
      GlobalCommands.find { |c| c.named? n }
    end
  end
end
