require 'json'
require "bundler/setup"
require "bunny"
class Chat

  ## ---------------------------
  ## -- display_message do:
  ## -- - print message in the correct format.
  ## ---------------------------
  def display_message(user, message)
    puts "#{user}: #{message}"
  end

  ## ---------------------------
  ## -- initialize do:
  ## -- - take user name,
  ## -- - create connection and channel,
  ## -- - listen for message to show you.
  ## ---------------------------
  def initialize
    print "Type in your name: "
    @current_user = gets.strip
    puts "Hi #{@current_user}, you just joined a chat room! Type your message in and press enter."

    conn = Bunny.new
    conn.start

    @channel = conn.create_channel
    @exchange = @channel.fanout("super.chat")

    listen_for_messages
  end

  ## ---------------------------
  ## -- listen_for_messages do:
  ## -- - create queue,
  ## -- - get the message,
  ## -- - decode message(payload) from JSON to user and message,
  ## -- - display message.  
  ## ---------------------------
  def listen_for_messages
    queue = @channel.queue("")

    queue.bind(@exchange).subscribe do |delivery_info, metadata, payload|
      data = JSON.parse(payload)
      display_message(data['user'], data['message'])
    end
  end

  ## ---------------------------
  ## -- publish_message do:
  ## -- - encode message into JSON,  
  ## -- - send message.  
  ## ---------------------------
  def publish_message(user, message)
    @exchange.publish({:user => user, :message => message}.to_json)
  end

  ## ---------------------------
  ## -- wait_for_message do:
  ## -- - get message from a prompt,  
  ## -- - publish message,
  ## -- - do it again.  
  ## ---------------------------
  def wait_for_message
    message = gets.strip
    publish_message(@current_user, message)
    wait_for_message
  end

end

chat = Chat.new
chat.wait_for_message
