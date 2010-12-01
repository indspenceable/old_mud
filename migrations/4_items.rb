module Mud
  #for something that has an inventory
  module HasInventory
    #retrieving the items from this character
    def find_item i
      items.find{|ci| ci.id?(i) || ci.named?(i)}
    end
    def items
      (@inventory ||= []).map{|id| W.items[id]}.freeze
    end
    #moving items around
    #generally, you don't even want to do do this. Let the item
    #take care of it for you.
    def remove_item id
      remove_from_all_slots id
      (@inventory ||= []).delete id
    end
    def add_item id
      @inventory << id unless (@inventory ||= []).include? id
    end
    #different item slots.
    def set_item slot, item
      (@item_slots ||= {})[slot] = (item ? item.id : nil)
    end
    def item_for slot
      if (id = (@item_slots ||= {})[slot])
        W.items[id]
      end
    end
    def remove_from_all_slots id
      (@item_slots ||= {}).each_pair do |k,v|
        @item_slots[k] = nil if v == id
      end
    end
  end

  class Item
    def initialize owner
      @@total_items ||= 0
      @@blank_ids ||= []
      @id = @@blank_ids.pop
      @id ||= (@@total_items += 1)

      puts "GENERATED AN ID #{@id}"

      W.items[@id] = self
      @owner = owner
      @owner.add_item @id
    end
    def kill
      W.items[@id] = nil
      @id = nil
      @owner.remove_item @id
    end
    def move_to new_owner
      raise "Item.move_to() to an object of type #{new_owner.class} that doesn't have an inventory." unless new_owner.is_a? HasInventory      
      @owner.remove_item @id
      new_owner.add_item @id
      @owner = new_owner
    end
    def id
      @id
    end
    def id? id
      id == @id
    end

    #ITEM SPECIFICATION
    # needs long_display_string
    # short_display_string
    # and named?

  end
end
