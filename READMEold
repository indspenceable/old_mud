Mud codebase

TODO -
  * Players taking damage
  * Afflictions
    * probably make a "Spell" class. There would be a mixin - has_spells
    * basically, would work almost exactly like items - you would always use the accessor methods
    * maybe, each one could have def process_x -> like process_output, process damage
    * and everything that could be processed could be processed by any applicable spells?
    * or should the methods just be aware of specific spells to begin with.
    * definitely, on ticks, spells should run
  * Mobiles
    * So a mobile and a player are both similar. The mob, on one hand, is the same except for 
    1) identification
    #TODO def sym
    #TODO is_named?
    2) display methods (display_name, display_description)
    #TODO display_name
    #TODO display_description
    3) On_load (this should be overriden by each mob, probably set up its ai)
    #TODO def on_load
    4) processing what it sees
    #TODO Controller ????
    #TODO receive_data ?????
    #TODO def hear_line
    #TODO def hear

    maybe it will also have a "react_to()"
  * Item actions
  * Equipment
