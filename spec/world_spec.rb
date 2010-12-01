require 'migrator'

module Mud
  describe "the world right after creation" do
    it "shouldn't have anything in it"

    it "should get angry if there is no default room; otherwise, return the right room" do
      ->(){W.default_room}.should raise_error(RuntimeError)
      default = Room.new(:default, "Default Room","This is the default_room")
      ->(){W.default_room = default}.should raise_error(RuntimeError)
      W.add_room default
      W.default_room = default
      W.default_room.should == default
    end
  end
end
