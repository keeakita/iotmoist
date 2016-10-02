# IoT Moist

The server software for an Internet of Things Humidifier written in Ruby with
Sinatra.

## What

At a hardware hackathon I modified a USB powered desk humidifier so that I could
read the LED and control power from a Raspberry Pi. This is the code that runs
it.

## Compiling & Running

This project is divided into two components: the Control server, which runs on
the Raspberry Pi, and the Web server, which serves the HTTP pages and API. The
two parts communicate via messages passed over RabbitMQ.

### Preliminary

This project relies on having and AMPQ server set up. I'm using
[https://www.rabbitmq.com/](RabbitMQ) personally. Copy `settings.sample.yml` to
`settings.yml` and edit it to contain the details of your AMPQ server. The
project needs to be able to declare and access the exchanges:
- `humidifier-state`
- `humidifier-command`

### The Control Server

All of the relevant files are in the directory `/control`.

IMPORTANT: Edit `control.rb` and `setup.sh` and define the proper pins. If you
mess this up something could get damaged!

Install Ruby 2.3.1, then:

```
bundle install
```

Create a `gpio` group on the server, then add your current user to it. Set up
all the pins (needs to be done every reboot):

```
sudo ./setup.sh
```

Finally, run the control server:

```
ruby moist.rb
```

### Web server

All of the relevant files are in the directory `/webserver`.

Install Ruby 2.3.1, then prepare the required gems:

```
bundle install
```

Either set the server up to run in a Rack-compatible configuration
(recommended), or run the server standalone with:

```
ruby webserver.rb
```

## API

`GET /`:  
Shows a user-friendly webpage

`GET /humidifier`:  
Get the status of the LEDs as JSON

`POST /humidifier`:  
Turn the humidifier on or off. Takes a JSON object in the body with `"power"`
set to `true` or `false`.
