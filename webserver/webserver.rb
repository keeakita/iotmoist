#!/bin/env ruby

# This file is the code meant to run on the web server. It serves up content to
# browsers and is responsible for communicating with the humidifier via the
# message queue.

require 'json'
require 'sinatra'
require_relative '../lib/message_queue.rb'

# Die if any thread does (Rack should restart the worker)
Thread.abort_on_exception = true

# Set up some initial states. Assume false until we hear otherwise
# FIXME: this will produce inconsistent results on this worker until next
# state update!
red_led_value = false
blue_led_value = false
power_on = false

state_mutex = Mutex.new

# Connect to the message queueing service
conn = MessageQueue::new_connection
state_exchange, state_chan = MessageQueue::get_state_exchange(conn)
command_exchange, _ = MessageQueue::get_command_exchange(conn)

# React to state changes
q = state_chan.queue('', exclusive: true)
q.bind(state_exchange)
q.subscribe do |delivery_info, properties, body|
  puts "State change: #{body}"

  begin
    change = JSON::parse(body)

    state_mutex.synchronize do
      if not change['red_led'].nil?
        red_led_value = change['red_led']
      elsif not change['blue_led'].nil?
        blue_led_value = change['blue_led']
      elsif not change['power'].nil?
        power_on = change['power']
      else
        STDERR.puts 'Got unknown change!'
      end
    end
  rescue Exception => e
    STDERR.puts 'Error processing set state update. Dropping.'
  end

  # cancel the consumer to exit
  #delivery_info.consumer.cancel
end

# Sinatra Routes start here
get '/' do
  send_file 'public/index.html'
end

get '/humidifier' do
  json_str = ""

  state_mutex.synchronize do
    puts json_str = {
      red_led: red_led_value,
      blue_led: blue_led_value,
      has_power: power_on
    }.to_json
  end

  [200, json_str]
end

post '/humidifier' do
  command = JSON::parse(request.body.read)
  response = 500

  if not command['power'].nil?
    pwr_set = command['power']
    if pwr_set == true or pwr_set == false

      command_exchange.publish(pwr_set.to_s);

      response = [200, {'Content-Type' => 'text/plain'}, 'Power value set.']
    else
      response = [400, {'Content-Type' => 'text/plain'},
                  'Invalid power value (must be true or false)']
    end

  else
    response = [400, {'Content-Type' => 'text/plain'}, 'No `power` value specified']
  end

  response
end
