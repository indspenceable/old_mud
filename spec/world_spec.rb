require 'migrator'
module Mud
  describe W, "The world" do
    it "Should be empty after setting up the state." do
      W.initialize_state
      W.players.size.should == 0
      W.rooms.size.should == 0
      W.items.size.should == 0
      W.mobiles.size.should == 0
      W.default_room.should raise_error(StandardError,"no default room")
    end
    it "Should correctly load the test scaffold" do
      Migrator::script('test_scaffold.rb')
    end
    it "Should now have a room" do
      W.default_room
      W.rooms.size.should > 0
    end
    
  end
end

