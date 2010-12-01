require 'migrator'

module Mud
  describe Room do
    it "should be able to add and remove rooms" do
      W.rooms.should be_empty
      r = Room.new(:test, "test_name", "this is the test room")
      W.add_room(r)
      W.add_room(Room.new(:test2, "test2_name", "this is the second test room"))
      W.add_room(Room.new(:test3, "test3_name", "this is the third test room"))
      W.rooms.size.should == 3
      W.rooms[:test].should == r
      W.rooms[:fail].should be nil
    end
    it "should get angry if there is no default room; otherwise, return the right room" do
      ->(){W.default_room}.should raise_error(RuntimeError)
      W.default_room = W.rooms[:test]
      W.defualt_room.should be W.rooms[:test]
    end
    it "should be able to manage exits between rooms" do
      t,t2,t3 = [:test,:test2,:test].map{|n| W.rooms[n]}
      t.has_exit?('n').should_not be true
      t.dig('north',:test2)
      t.has_exit?('n').should be true
      t.dig('north',:test2)
      t.dest('n').should == t2
      t.dest('north').should == t2
      t.dig('north',:test3)
      t.dest('n').should == t3
      t.dest('north').should == t3
      t.fill('north')
      t.has_exit?('n').should_not be true
      t.dest('north').should be nil
    end


  end
end
