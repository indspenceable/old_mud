module Mud 
  module Entities 
    module Hostile
      def anger
        @anger ||= {}
      end
      def react_to_attack actor
        anger[actor.sym] = 1000
      end
      def update_anger dt
        anger.each_pair do |k,v|
          anger[k] = v-dt
        end
        anger.reject! { |k,v| v <= 0 }
      end
      def determine_attack 
        if (on_balance? :all) && (anger.size > 0)
          target = anger.to_a.sort{ |l,r| l[1] <=> r[1] }.find{|v| (room.find_player v[0].to_s)||(room.find_mobile v[0].to_s)}
          target = target[0] if target
          attack target if target
        end
      end
    end


    class Rat < Mobile
      include Hostile
      def initialize *args
        super
        @hp = @max_hp = 30
      end
      def tick dt
        update_balance dt
        update_anger dt
        determine_attack
      end
      def attack tar
        command "punch #{tar}"
      end
      def is_named? n
        ['rat', 'vermin'].include? n.downcase
      end
      def display_name
        "a mangy rat"
      end
      def display_description
        'A mangy rat skitters about here.'
      end
    end
  end
  module Items
    class Dagger < Item
      def long_display_string
        "a sharp dagger has been carelessly discarded here."
      end
      def short_display_string
        "a dagger"
      end
      def named? n
        n.downcase == "dagger"
      end
    end
  end
end
