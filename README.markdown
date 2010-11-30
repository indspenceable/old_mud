# Mud codebase

## TODO -
### Players taking damage
### Afflictions
Afflictions are, essentially, buffs and debuffs. You would be able to assign negative afflictions to your enemies, and get yourself positive buffs. To a certain extent things would need to know about them, but sometimes they could also be selfcontained.

- probably make a "Spell" class. There would be a mixin - has_spells
- basically, would work almost exactly like items - you would always use the accessor methods
- maybe, each one could have def process_x -> like process_output, process damage
- and everything that could be processed could be processed by any applicable spells?
- or should the methods just be aware of specific spells to begin with.
- definitely, on ticks, spells should run

### Mobiles
So a mobile and a player are both similar. The mob, on one hand, is the same except for 

- identification
        `def sym`
        `is_named?`
- display methods (display_name, display_description)
        `display_name`
        `display_description`
- On_load (this should be overriden by each mob, probably set up its ai)
        `def on_load`
- processing what it sees
        `controller` ?
        `receive_data` ?
        `hear_line`
        `hear`
- maybe it will also have a `react_to()`
    - This is actually, great.

### Item actions

### Equipment
- I have some items. You can use the sword as a weapon
