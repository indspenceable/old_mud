#!/usr/bin/env ruby

require 'eventmachine'
require './migrations/migrator.rb'

EventMachine::run do
  host = '0.0.0.0'
  port = 8080
  Mud::Migrator.migrate
  Mud::W.load_state

  EventMachine::start_server host, port, Mud::Connection
  puts "listening at #{host} on #{port}"
  EventMachine::PeriodicTimer.new(0) do
    Mud::W.players.each do |p|
      p.flush_output
    end
  end
  EventMachine::PeriodicTimer.new(20) do
    puts "Hello, world."
    Mud::W.dump_state
  end
end
