module Mud
  module Commands
    class Shutdown < Command
      def initialize
        super("shutdown",[])
      end
      def enact player, args
        EventMachine::stop_event_loop
      end
    end
    GlobalCommands << Shutdown.new
  end
end
