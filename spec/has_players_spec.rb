require 'migrator'

module Mud
  module Entities
    describe HasPlayers do
      describe "the players in this room" do
        before(:all) do
          W.initialize_state
          (@o = Object.new).extend(HasPlayers)
          W.add_room(Room.new(:default,"title","text"))
          W.default_room = (W.rooms[:default])
          @mock_player = Player.new "mock", "mock"
        end
        it "should start with no mobs" do
          @o.players.size.should be 0
        end
        it "should be able to add a player" do
          @o.add_player(@mock_player)
          @o.find_player("mock").should be @mock_player
          @o.find_player("not_mock").should be nil
          @o.players.size.should be 1
          @o.players.include?(@mock_player).should == true 
        end
        it "should be able to remove a player" do
          @o.remove_player(@mock_player)
          @o.players.size.should be 0
          @o.players.include?(@mock_player).should == false
        end
      end
    end
  end
end
