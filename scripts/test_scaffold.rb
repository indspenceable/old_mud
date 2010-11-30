module Mud
  r1 = Room.new(:hub, "hub", "this is the center of the world.")
  W.default_room = r1
  W.add_room r1
end
