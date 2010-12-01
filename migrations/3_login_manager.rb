require 'digest/md5'

module Mud
  # The login class represents someone who is attempting to login to the 
  # Mud. It handles intermediate state while they do that
  class Login
    def initialize con
      @connection = con 
      @connection.send_line welcome_message
      @current_state = :choose_character
    end

    # the message that gets displayed when a player initially connects.
    def welcome_message
      "Welcome to the mud! Enter [new] to create a new character, or enter your characters name to continue"
    end
    # Prompt for selecting a character name, during character creation
    def choose_character_name_message
      "Please select a character name."
    end
    # prompt for entering password
    def enter_password_message
      "Please enter your password"
    end

    # message to display upon successful login
    def login_message
      "Success!"
    end

    # When we recieve input from the player, run the correct method
    # for whatever our current state is.
    def receive_data data
      self.send(@current_state, data)
    end

    def choose_character data
      if data=="new" 
        @connection.send_line choose_character_name_message
        @current_state = :choose_character_name
      else
        if !W.valid_name? data
          @connection.send_line "that's not a valid character name"
        else
          unless (pl = W.find_player(data))
            @connection.send_line "There's no player by that name."
          else
            @connection.send_line enter_password_message
            @player = pl
            @current_state = :enter_password
          end
        end
      end
    end

    def choose_character_name data
      if W.find_player(data)
        @connection.send_line "Sorry, that name is already taken."
        @connection.send_line choose_character_name_message
      elsif !W.valid_name? data
        @connection.send_line "Sorry, that name is invalid"
        @connection.send_line choose_character_name_message
      else # Valid, unclaimed name
        @connection.send_line "Please enter a password for your new character."
        @player_name = data
        @current_state = :choose_password
      end
    end

    def choose_password data
      if !W.valid_password? data
        @connection.send_line "Sorry, that is an invalid password."
        initialize @connection
      elsif W.find_player(@player_name)
        @connection.send_line "That sucks! While you were registering, someone else created a character with that name. Try again! "
        initialize @connection
      else
        @connection.send_line "Congratulations! You now exist. Pretty cool!"
        pl = Entities::Player.new(@player_name,Digest::MD5.hexdigest(data))
        pl.connection = @connection
        pl.login
        @connection.delegate = pl
      end
    end

    def logout
    end

    def enter_password data
      if Digest::MD5.hexdigest(data) == @player.hashed_password
        @connection.send_line login_message

        #is the player already logged in?
        if W.players.include? @player
          @player.hear_line "You've been logged in from another location"
          @player.flush_output
          @player.connection.delegate = Login.new(@player.connection)
          @player.connection = @connection
          @connection.delegate = @player
        else
          @player.room.add_player @player
          W.players<< @player
          @player.connection = @connection
          @connection.delegate = @player
        end
      else
        @connection.send_line "Incorrect password"
        initialize @connection
      end
    end
  end
end
