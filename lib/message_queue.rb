require 'yaml'
require 'bunny'

module MessageQueue
  @@server_settings = {}

  # YAML loads the file with string keys, but need symbols for connect
  YAML::load_file('../settings.yml')['mq'].each_pair do |key, val|
    @@server_settings[key.to_sym] = val
  end

  puts @@server_settings.inspect

  def self.new_connection
    conn = Bunny.new(@@server_settings)
    conn.start

    return conn
  end

  def self.get_state_exchange(conn)
    ch = conn.create_channel
    return [ch.fanout('humidifer-state'), ch]
  end

  def self.get_command_exchange(conn)
    ch = conn.create_channel
    return [ch.fanout('humidifer-command'), ch]
  end
end
