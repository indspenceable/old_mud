require 'migrator'

module Mud
  describe Room do
    before(:all) do
      W.initialize_state
      @r  = Room.new(:test, "test_name", "this is the test room")
      @r2 = Room.new(:test2, "test2_name", "this is the second test room")
      @r3 = Room.new(:test3, "test3_name", "this is the third test room")
      W.add_room(@r)
      W.add_room(@r2)
      W.add_room(@r3)
    end
    describe "A new room" do
      it "should start with no exit" do
        @r.has_exit?('n').should_not be true
        @r.exits_string.should == "There are no exits."
      end

      it "should be able to add a texture, and use either short or long names" do
        @r.dig('north',:test2)
        @r.has_exit?('n').should be true
        @r.dest('n').should == @r2
        @r.dest('north').should == @r2
        @r.exits_string.should == "You see an exit to the north."
      end

      it "should be able to overwrite old exits" do
        @r.dig('north',:test3)
        @r.dest('n').should == @r3
        @r.dest('north').should == @r3
        @r.exits_string.should == "You see an exit to the north."
      end

      it "should be able to fill in old exits" do
        @r.fill('north')
        @r.has_exit?('n').should_not be true
        @r.dest('north').should be nil
        @r.exits_string.should == "There are no exits."
      end
    end
  end
end
