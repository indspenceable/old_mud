#!/usr/bin/env ruby

require 'eventmachine'
require './migrations/migrator.rb'

EventMachine::run do
  host = '0.0.0.0'
  port = 8080
  Mud::Migrator.migrate
  Mud::W.load_state

  last_time = Time.now.to_f * 100

  EventMachine::start_server host, port, Mud::Connection
  puts "listening at #{host} on #{port}"
  EventMachine::PeriodicTimer.new(0) do
    dt = Time.now.to_f*100 - last_time
    Mud::W.players.each do |p|
      p.tick dt
    end
    Mud::W.mobiles.each do |m|
      m.tick dt if m
    end
    last_time = Time.now.to_f * 100
  end
end
