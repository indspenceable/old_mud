module Mud
  module Migrator
    def self.determine_file_to_load
        directory = File.join(File.dirname(File.expand_path(__FILE__)),'..','saves')
        entries = Dir.entries(directory)
        entries.reject!{|en| (en=~/\A\d{4}_\d{2}_\d{2}_\d{2}_\d{2}\.yaml\z/).nil?}
        File.join(directory,entries[entries.size - 1])
        # yml = W.load_state(YAML.parse_file load_from)
    end
    def self.script file_name
      require File.join(File.expand_path(File.dirname(__FILE__)),'..','scripts', file_name)
    end
    def self.migrate
      (@migration_index ||= 0)
      (@migration_hash ||= Hash.new)
      #directory = File.join(File.expand_path(File.dirname(__FILE__)), 'migrations')
      directory = File.join(File.expand_path(File.dirname(__FILE__)),"..","migrations")
      migrations = Dir.entries(directory)
      migrations.reject! do |m|
        !(/\A(\d*)_(.*)\z/.match m)
      end
      #put each file name in the migration hash.
      migrations.each do |m|
        @migration_hash[(/\A([0-9]*)_(.*)\z/.match m)[1].to_i] = m
      end
      puts @migration_hash.inspect

      while @migration_hash.key?(@migration_index + 1)
        require File.join(directory, @migration_hash[@migration_index += 1])
        puts "Loaded migration ##{@migration_index}"
      end
    end
  end
end
Mud::Migrator.migrate
