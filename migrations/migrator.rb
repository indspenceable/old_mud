module Mud
  module Migrator
    def self.script file_name
      require File.join(File.expand_path(File.dirname(__FILE__)),'..','scripts', file_name)
    end
    def self.migrate
      (@migration_index ||= 0)
      (@migration_hash ||= Hash.new)
      #directory = File.join(File.expand_path(File.dirname(__FILE__)), 'migrations')
      directory = File.expand_path(File.dirname(__FILE__))
      migrations = Dir.entries(directory)
      migrations.reject! do |m|
        !(/\A(\d)_(.*)\z/.match m)
      end
      #put each file name in the migration hash.
      migrations.each do |m|
        @migration_hash[(/\A(\d)_(.*)\z/.match m)[1].to_i] = m
      end

      while @migration_hash.key?(@migration_index + 1)
        require File.join(directory, @migration_hash[@migration_index += 1])
        puts "Loaded migration ##{@migration_index}"
      end
    end
  end

end
