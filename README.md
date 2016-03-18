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

The server can be run with:

```
nim c moist.nim
sudo ./moist.nim
```

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
