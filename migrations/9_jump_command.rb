module Mud
  module Commands
    class Jump < Command
      def initialize
        super("jump",[])
      end
      def enact player, args
        player.room.echo "#{player.name} jumps up and down.", [player]
        player.hear_line "You jump up and down"
      end
      GlobalCommands << Jump.new
    end
  end
end
