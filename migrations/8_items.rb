module Mud
  class Item
    def initialize owner
      @@total_items ||= 0
      @@blank_ids ||= []
      @id = @@blank_ids.pop
      @id ||= @total_items =+ 1 
      W.items[@id] = self
      @owner = owner
      owner.add_item @id
    end
    def kill
      W.items[@id] = nil
      @id = nil
      owner.remove_item @id
    end
    def move_to new_owner
      raise "Item.move_to() to an object of type #{new_owner.class} that doesn't have an inventory." unless new_owner.is_a? HasInventory      
      owner.remove_item @id
      new_owner.add_item @id
      self.owner = new_owner
    end
  end

  class Sword < Item
    def display_name
      "A shining sword"
    end
  end
end
