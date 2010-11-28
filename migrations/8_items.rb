module Mud
  class Item
    def initialize owner
      @@total_items ||= 0
      @@blank_ids ||= []
      @id = @@blank_ids.pop
      @id ||= @total_items =+ 1 
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
    
    def id? id
      id == @id
    end
  end


  class StandardItem < Item
    def initialize owner, display_string, name_list
      super(owner)
      @display_string = display_string
      @name_list = name_list
    end
    def display_string
      @display_string
    end
    def named? n
      @name_list.include? n
    end
  end

  class Sword < StandardItem
    def initialize owner
      super(owner, "A faintly glowing sword", ["sword", "blade"])
    end
  end
end
