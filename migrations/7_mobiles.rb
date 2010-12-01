module Mud
  module Entities
    module HasMobiles
      #retrieving the items from this character
      def find_mobile p
        mobiles.find{|cp| p == cp}
      end
      def mobiles
        (@mobiles ||= []).map{|id| W.mobiles[id]}.freeze
      end

      #moving players around.
      #let players do this
      def remove_mobile p
        (@mobiles ||= []).delete p.sym
      end
      def add_mobile p
        @mobiles << p.sym unless (@mobiles ||= []).include? p.sym
      end

      #trigger reactions
      def trigger_reaction reaction_type, actor, *args
        mobiles.each do |m|
          m.react_to(reaction_type, actor, *args)
        end
      end
    end

    # A mapping of color symbols to their escape sequences.

    class Mobile < Entity
      attr_reader :id
      def initialize
        @@total_items ||= 0
        @@blank_ids ||= []
        @id = @@blank_ids.pop
        @id ||= (@@total_items += 1)

        @off_balance_timer = {}
      end
      def sym
        @id
      end
      def move_to new_room
        self.room.remove_mobile self
        self.room = new_room 
        new_room.add_mobile self
      end
      def hear_line *args; end
      def react_to reaction_type, actor, *args
        method = ("react_to_" + reaction_type.to_s).to_sym
        send(method, actor, *args) if respond_to? method
      end
    end
  end
end
