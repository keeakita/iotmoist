#!/bin/env ruby

# This file is the code meant to run on the humidifier server. It monitors and
# changes humidifier state based on messages from the queue.

require_relative '../lib/message_queue.rb'

# GPIO directory
GPIO_DIR = '/sys/class/gpio/'

# Input pins
RED_LED = '10'
BLUE_LED = '9'

# Ouput pins
USB_POWER = '15'

# Polling interval for setting the pin, in seconds
TIMEOUT = 1

# If any thread dies, so should this process
Thread.abort_on_exception = true

# writes a single line string to the file at the given path. Returns true if
# successful.
def file_write(what, where)
  f = File.new(where, 'w')
  f.puts(what)
  f.close()
end

# Reads a file
def cat(where)
  return File.read(where)
end

# Set up some initial states
prev_power = cat("#{GPIO_DIR}gpio#{USB_POWER}/value") == "1"

power_on = prev_power
power_mutex = Mutex.new

# Connect to the message queueing service
conn = MessageQueue::new_connection
state_exchange, _ = MessageQueue::get_state_exchange(conn)
command_exchange, command_chan = MessageQueue::get_command_exchange(conn)

# React to commands
q = command_chan.queue('', exclusive: true)
q.bind(command_exchange)
q.subscribe do |delivery_info, properties, body|
  puts "Command: #{body}"

  power_mutex.synchronize do
    power_on = (body == 'true')
  end
end

# A timer loop that actually controls the humidifier. Used to prevent a
# malicious client from rapidly toggling the state and damaging hardware.
Thread.new do
  loop do
    power_mutex.synchronize do
      if power_on != prev_power
        pwr_str = power_on ? '1' : '0'
        file_write(pwr_str, "#{GPIO_DIR}gpio#{USB_POWER}/value")
        state_exchange.publish("{\"power\":#{power_on}}")
        prev_power = power_on
      end
    end

    # Limit how often the check runs
    sleep(TIMEOUT)
  end
end

# The main loop for monitoring changes to the LEDs
red_file = File.open("#{GPIO_DIR}gpio#{RED_LED}/value", 'r')
blue_file = File.open("#{GPIO_DIR}gpio#{BLUE_LED}/value", 'r')
loop do
  updated = IO.select(nil, nil, [red_file, blue_file]).flatten

  if (updated.include?(red_file))
    red_led_value = red_file.read(1)
    puts "Red updated: #{red_led_value}"
    state_exchange.publish("{\"red_led\":#{red_led_value}}")
    red_file.rewind()
  end

  if (updated.include?(blue_file))
    blue_led_value = blue_file.read(1)
    puts "Blue updated: #{blue_led_value}"
    state_exchange.publish("{\"blue_led\":#{blue_led_value}}")
    blue_file.rewind()
  end
end
