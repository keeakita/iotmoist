require 'json'
require 'sinatra'

# GPIO directory
GPIO_DIR = '/sys/class/gpio/'

# Input pins
RED_LED = '10'
BLUE_LED = '9'

# Ouput pins
USB_POWER = '15'

# Polling interval for setting the pin, in milliseconds
TIMEOUT = 1

# Enable testing from the local network
configure do
  set bind: '0.0.0.0'
end

# Prints an error message and terminates
def die(why)
  puts why
  exit(254)
end

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
red_led_value = cat("#{GPIO_DIR}gpio#{RED_LED}/value") == "1"
blue_led_value = cat("#{GPIO_DIR}gpio#{BLUE_LED}/value") == "1"

power_on = prev_power
power_mutex = Mutex.new
led_mutex = Mutex.new

# A timer loop that actually controls the humidifier. Used to prevent a
# malicious client from rapidly toggling the state and damaging hardware.
Thread.abort_on_exception = true
Thread.new do
  loop do
    power_mutex.synchronize do
      if power_on != prev_power
        puts "Changed state: #{power_on}"
        pwr_str = power_on ? "1" : "0"
        file_write(pwr_str, "#{GPIO_DIR}gpio#{USB_POWER}/value")
        prev_power = power_on
      end
    end

    # Limit how often the check runs
    sleep(TIMEOUT)
  end
end

# A thread for monitoring changes to the LEDs
Thread.new do
  red_file = File.open("#{GPIO_DIR}gpio#{RED_LED}/value", 'r')
  blue_file = File.open("#{GPIO_DIR}gpio#{BLUE_LED}/value", 'r')
  loop do
    _,_,updated = IO.select(nil, nil, [red_file, blue_file])
    led_mutex.synchronize do
      if (updated == red_file)
        red_led_value = (red_file.read(1) == '1')
        red_file.rewind()
      else
        blue_led_value = (blue_file.read(1) == '1')
        blue_file.rewind()
      end
    end
  end
end

# Sinatra Routes start here
get '/' do
  send_file 'public/index.html'
end

get '/humidifier' do
  json_str = ""

  led_mutex.synchronize do
    power_mutex.synchronize do
      json_str = {
        red_led: red_led_value,
        blue_led: blue_led_value,
        has_power: power_on
      }.to_s
    end
  end

  [200, json_str]
end

post '/humidifier' do
  command = JSON::parse(request.body.read)
  response = 500

  if not command['power'].nil?
    power_mutex.synchronize do
      pwr_set = command['power']
      if pwr_set == true or pwr_set == false
        power_on = pwr_set
        response = [200, {'Content-Type' => 'text/plain'}, 'Power value set.']
      else
        response = [400, {'Content-Type' => 'text/plain'},
                    'Invalid power value (must be true or false)']
      end
    end

  else
    response = [400, {'Content-Type' => 'text/plain'}, 'No `power` value specified']
  end

  response
end
