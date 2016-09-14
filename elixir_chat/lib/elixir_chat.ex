defmodule ElixirChat do

  ## ---------------------------
  ## -- start do:
  ## -- - take user name,
  ## -- - create connection, channel and queue,
  ## -- - make fanout exchange that routes messages to all of the queues,
  ## -- - create relationship between an exchange and a queue,
  ## -- - listen for message to show you,
  ## -- - wait for your message to send.
  ## ---------------------------
  def start do
    user = IO.gets("Type in your name: ") |> String.strip
    IO.puts "Hi #{user}, you just joined a chat room! Type your message in and press enter."

    {:ok, conn} = AMQP.Connection.open
    {:ok, channel} = AMQP.Channel.open(conn)
    {:ok, queue_data } = AMQP.Queue.declare channel, ""

    AMQP.Exchange.fanout(channel, "super.chat")
    AMQP.Queue.bind channel, queue_data.queue, "super.chat"

    listen_for_messages(channel, queue_data.queue)
    wait_for_message(user, channel)
  end

  ## ---------------------------
  ## -- wait_for_message do:
  ## -- - take your message from a prompt,
  ## -- - publish the message,
  ## -- - do it again.
  ## ---------------------------
  def wait_for_message(user, channel) do
    message = IO.gets("") |> String.strip
    publish_message(user, message, channel)
    wait_for_message(user, channel)
  end

  ## ---------------------------
  ## -- listen_for_messages do:
  ## -- - create a consumer of messages,
  ## -- - delivered message(payload) is decoded from JSON to user and message,
  ## -- - print message in the correct format.
  ## ---------------------------
  def listen_for_messages(channel, queue_name) do
    AMQP.Queue.subscribe channel, queue_name, fn(payload, _meta) ->
      {_, msg} = JSON.decode(payload)
      IO.puts("#{msg["user"]}: #{msg["message"]}")
    end
  end

  ## ---------------------------
  ## -- publish_message do:
  ## -- - encodes a message in correct format,
  ## -- - send message.
  ## ---------------------------
  def publish_message(user, message, channel) do
    { :ok, data } = JSON.encode([user: user, message: message])
    AMQP.Basic.publish channel, "super.chat", "", data
  end

end

ElixirChat.start
