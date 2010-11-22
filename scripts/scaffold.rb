module Mud
  r1 = Room.new("Hub", "this is the central hub of the world. BOOM!")
  r2 = Room.new("Cave", "you are in a small cave.")
  r1.dig(:north, r2)
  r2.dig(:south, r1)
  W.default_room = r1
  W.rooms << r1 << r2
end
