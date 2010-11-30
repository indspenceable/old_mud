# set up the world. 
# it is a singleton, which you can access by the constant W
# with a list of active players

require 'singleton'
require 'yaml'


module Mud

  #this is for utility
  def self.list_array ary, default_message = ""
    case
    when ary.size == 0
      default_message
    when ary.size == 1
      ary[0]
    else
      ary.first(ary.size - 1).join(", ") + " and " + ary[ary.size-1]
    end
  end


  # The world has all the global data about the game - a master list of 
  # players, the list of logged in players, all of the rooms, and all the 
  # items
  class World
    include Singleton
    attr_reader :players, :items
    attr_accessor :player_connection_map

    def rooms
      @rooms.dup.freeze
    end

    def find_player(n)
      n = n.downcase.to_sym if n.is_a? String
      @master_players[n]
    end
    def create_player(p)
      @master_players[p.sym] = p
    end

    def initialize 
      initialize_state
    end

    def initialize_state
      @player_connection_map = {}
      @master_players = {}
      @players = []
      @rooms = {}
      @items = []
      @mobiles = []
    end

    # This lets us load up the gamestate. A bunch of info is hashshed into 
    # the yaml file, so we read it into our variables. Of course, when you 
    # load a world, no players should be anywhere, so we also must manually 
    # go through and remove players from the rooms load state will not save 
    # connections 
    def load_state 
      begin
        directory = File.join(File.dirname(File.expand_path(__FILE__)),'..','saves')
        entries = Dir.entries(directory)
        entries.reject!{|en| (en=~/\A\d{4}_\d{2}_\d{2}_\d{2}_\d{2}\.yaml\z/).nil?}
        load_from = entries[entries.size - 1]
        # yml = W.load_state(YAML.parse_file load_from)
        yml = YAML.load_file(File.join(directory,load_from))
        puts "Loading #{directory}/#{load_from}..."
        raise "Yaml is nil" unless yml
        @master_players, @rooms, @default_room, @items= yml
        @rooms.each_pair { |n,r| r.on_load }
        @master_players.each_pair { |n,p| p.on_load }
        puts "Loaded Game."
      rescue Object => e
        puts 'There was an error wtih loading'
        puts "************************************************"
        puts e.backtrace
        puts "************************************************"
        puts 'running the scaffolding script instead.'
        initialize_state
        Migrator.script('scaffold.rb')
      end
    end
    # Save the state. This saves data in the same format the load_state reads. TODO - Make it not save the connections
    def dump_state
      f = File.new(File.join(File.dirname(File.expand_path(__FILE__)),"..","saves","#{Time.now.strftime("%Y_%m_%d_%H_%M")}.yaml"),"w")
      f << YAML.dump([@master_players, @rooms, @items, @default_room])
      f.close
      puts "Saved game."
    end

    # determine if a name is valid. This just checks the rexegp
    # Maybe, in the future, it should return symbols reprepsenting
    # problems - so, you check validity, and it returns :already_exists
    # if someone has that name, or :tooshort if its too short, etc
    def valid_name? n
      /\A[a-zA-Z]{3,20}\z/.match(n)
    end
    # determine if a new password is valid. DOES NOT SAVE THE PASSWORD all passwords will be hashed before they are saved.
    # I should probably write a "hash_password" method, so I can update
    # the hashing situation in an encapsulated manner.
    def valid_password? n
      /\A[a-zA-Z1-9]{5,20}\z/.match(n)
    end

    # get the default room, or raise an error if none exists
    def default_room
      raise "no default room" unless @default_room
      rooms[@default_room]
    end
    def default_room= r
      @default_room = r.sym
    end

    def add_room r
      raise "Already a room with that name." if @rooms.key? r.name.to_sym
      @rooms[r.sym] = r
    end

    def each_room
      @rooms.each_pair do |n,r|
        yield r
      end
    end
  end
end

