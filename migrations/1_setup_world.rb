# set up the world. 
# it is a singleton, which you can access by the constant W
# with a list of active players

require 'singleton'
require 'yaml'

module Mud
  # The world has all the global data about the game - a master list of 
  # players, the list of logged in players, all of the rooms, and all the 
  # items
  class World
    include Singleton
    attr_reader :master_players, :players, :rooms, :items
    attr_accessor :default_room

    def initialize 
      @master_players = []
      @players = []
      @rooms = []
      @items = []
    end

    # This lets us load up the gamestate. A bunch of info is hashshed into 
    # the yaml file, so we read it into our variables. Of course, when you 
    # load a world, no players should be anywhere, so we also must manually 
    # go through and remove players from the rooms load state will not save 
    # connections 
    def load_state 
      # loading state.
      begin
        directory = File.join(File.dirname(File.expand_path(__FILE__)),'..','saves')
        entries = Dir.entries(directory)
        entries.reject!{|en| (en=~/\A\d{4}_\d{2}_\d{2}_\d{2}_\d{2}\.yaml\z/).nil?}
        load_from = entries[0]
        # yml = W.load_state(YAML.parse_file load_from)
        puts "HI"
        yml = YAML.load_file(File.join(directory,load_from))
        puts "YAML IS : # {yml}"
        @master_players, @rooms, @default_room = yml
        @rooms.each { |r| r.players.clear }

        puts "HI"
      rescue Object => e
        puts 'There was an error wtih loading'
        puts e.backtrace
        puts 'running the scaffolding script instead.'
        Migrator.script('scaffold.rb')
      end
    end
    # Save the state. This saves data in the same format the load_state reads. TODO - Make it not save the connections
    def dump_state
      f = File.new(File.join(File.dirname(File.expand_path(__FILE__)),"..","saves","#{Time.now.strftime("%Y_%m_%d_%H_%M")}.yaml"),"w")
      f << JSON.dump([@master_players, @rooms, @default_room])
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
      raise "No default room!" unless @default_room
      @default_room
    end
  end
  W = World.instance
end

