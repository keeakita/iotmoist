# IoT Moist

The server software for an Internet of Things Humidifier written in Nim with
Jester.

## What

At a hardware hackathon I modified a USB powered desk humidifier so that I could
read the LED and control power from a Raspberry Pi. This code is the server
component.

## Compiling & Running

IMPORTANT: Edit `moist.nim` and define the proper pins. If you mess this up
something could get damaged!

Install nimble using your package manager, then:

```
nimble install jester
```

Next, install the `haml` Ruby gem and build the page:

```
gem install haml
make
```

To run the server securely, as a non-root user:

```
nim c moist.nim
sudo chown root:root moist
sudo chmod 711 moist
sudo chmod u+s moist
./moist
```

Note that the server will bail if run directly as root for security reasons.

To create a release build, run:

```
nim c -d:release moist.nim
```

Be aware that release builds can take a while on the Pi.

## API

`GET /`:  
Get a welcome message

`GET /humidifier`:  
Get the status of the LEDs as JSON

`POST /humidifier`:  
Turn the humidifier on or off. Takes a JSON object in the body with `"power"`
set to `"1"` or `"0"`.
