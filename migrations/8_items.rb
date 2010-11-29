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

  #mixin to be a weapon!
  module Weapon
    # weapons should have
    # weapon.hands # => 1 || 2
    # def actions
  end


  class StandardItem < Item
    attr_reader :long_display_string, :short_display_string, :names
    def initialize owner, long_display_string, short_display_string, name_list = []
      super(owner)
      @long_display_string = long_display_string
      @short_display_string = short_display_string
      @names = name_list
    end

    def named? n; @names.include? n; end
    def names; @names.dup.freeze; end

    def register name
      @names << name unless @names.include? name
    end
  end

  class Sword < StandardItem
    def initialize owner
      super(owner, "A faintly glowing sword has been discarded here.", "a glowing sword", ["sword", "blade"])
    end
  end
end
