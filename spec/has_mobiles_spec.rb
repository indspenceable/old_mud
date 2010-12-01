require 'migrator'

module Mud
  module Entities
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
          @o.find_mobile(Mobile.new).should be nil
          @o.mobiles.size.should be 1
          @o.mobiles.include?(@mock_mobile).should == true 
        end
        it "should be able to remove a mobile" do
          @o.remove_mobile(@mock_mobile)
          @o.mobiles.size.should be 0
          @o.mobiles.include?(@mock_mobile).should == false
        end
      end
    end
  end
end
