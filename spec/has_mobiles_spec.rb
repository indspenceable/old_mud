require 'migrator'

module Mud
  describe HasMobiles do
    describe "the mobiles in this room" do
      before(:all) do
        (@o = Object.new).extend(HasMobiles)
        @mock_mobile = Mobile.new
      end
      it "should start with no mobs" do
        @o.mobiles.size.should be 0
      end
      it "should be able to add a mobile" do
        @o.add_mobile(@mock_mobile)
        @o.mobiles.size.should be 1
        #@r.mobiles.include?(@mock_mobile).should == true 
      end
      it "should be able to remove a mobile" do
        #@r.remove_mobile(@mock_mobile)
        @o.mobiles.size.should be 1
        #@r.mobiles.include?(@mock_mobile).should == true 
      end
      it "should be able to announce when a mob leaves" do
        #@r.add_mobile(@mock_mobile)
        #@r.leave_to(@mock_mobile, 'north').arrive_from(@mock_mobile, 'south')
      end
    end
  end
end
