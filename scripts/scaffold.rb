module Mud
  r1 = Room.new(:hub, "Hub", "this is the central hub of the world. BOOM!")
  r2 = Room.new(:cave001, "Cave", "you are in a small cave.")
  r1.dig(:north, :cave001)
  r2.dig(:south, :hub)
  W.add_room r1
  W.add_room r2
  W.default_room = r1
  p = Entities::Player.new "danny", Digest::MD5.hexdigest('danny')
  p.command_groups << :admin
  p.command_groups << :builder

  Entities::Rat.new(r1)
  Items::Dagger.new(p)
end
