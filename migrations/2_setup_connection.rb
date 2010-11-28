# This implementation of a connection is based on EventMachine.

require 'eventmachine'

module Mud
  class Connection < EventMachine::Connection
    attr_accessor :delegate

    # Create a delegate upon creation
    def post_init
      # first, make a logon for this guy, and set it to be our delegate
      @delegate = Login.new self
    end

    # forward (chommped) data to delegate
    def receive_data data
      @delegate.receive_data data.chomp
    end

    # sends data + newline
    def send_line data
      send_data data + "\n"
    end

    # logout our delegate
    def unbind
      @delegate.logout
    end
  end
end
