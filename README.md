# IoT Moist

The server software for an Internet of Things Humidifier written in Ruby with
Sinatra.

## What

At a hardware hackathon I modified a USB powered desk humidifier so that I could
read the LED and control power from a Raspberry Pi. This code is the server
component.

## Compiling & Running

IMPORTANT: Edit `moist.rb` and `setup.sh` and define the proper pins. If you
mess this up something could get damaged!

Install Ruby 2.3.1, then:

```
bundle install
make
```

Create a `gpio` group on the server, then add your current user to it. Set up
all the pins (needs to be done every reboot):

```
sudo ./setup.sh
```

Finally, run the server:

```
ruby moist.rb
```

## API

`GET /`:  
Shows a user-friendly webpage

`GET /humidifier`:  
Get the status of the LEDs as JSON

`POST /humidifier`:  
Turn the humidifier on or off. Takes a JSON object in the body with `"power"`
set to `true` or `false`.
