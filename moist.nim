import jester, asyncdispatch, htmlgen, streams, json, os, posix

const
    # GPIO directory
    GPIO_DIR = "/sys/class/gpio/"

    # Input pins
    RED_LED   = "10"
    BLUE_LED  = "9"

    # Ouput pins
    USB_POWER = "15"

    # Polling interval for setting the pin, in milliseconds
    TIMEOUT = 1000

var
  prev_power = false
  power_on = false

# Prints an error message and terminates
proc die(why: string) =
    echo why
    quit(QuitFailure)

# writes a single line string to the file at the given path. Returns true if
# successful.
proc file_write(what: string, where: string): bool =
    var fs = newFileStream(where, fmWrite)
    if not isNil(fs):
        fs.writeLine(what)
        fs.flush()
        fs.close()
        result = true
    else:
        result = false

# Reads a single line from a file
proc cat(where: string): string =
    var fs = newFileStream(where, fmRead)
    if not isNil(fs):
        result = fs.readLine()
        fs.close()
    else:
        result = ""

# Exports a pin. Returns true if success or already exported
proc export_pin(pin: string): bool =
    # Check if it already eixsts
    result = existsDir(GPIO_DIR & "gpio" & pin) or
        file_write(pin, GPIO_DIR & "export")

# Sets up a pin for input. Returns true if successful
proc setup_input(pin: string): bool =
    result = export_pin(pin) and
        file_write("in", GPIO_DIR & "gpio" & pin & "/direction")

# Sets up a pin for output. Returns true if successful
proc setup_output(pin: string): bool =
    result = export_pin(pin) and
        file_write("out", GPIO_DIR & "gpio" & pin & "/direction")

proc setup() =
    # Input
    if not setup_input(BLUE_LED):
        die("Could not set up blue LED")

    if not setup_input(RED_LED):
        die("Could not set up red LED")

    # Output
    if not setup_output(USB_POWER):
        die("Could not set up usb power out")

    # Surrender root privileges
    if setegid(getgid()) == -1 or getegid() == Gid(0):
      echo("Failed to surrender root group! Backing out for security!")

    if seteuid(getuid()) == -1 or geteuid() == Uid(0):
      echo("Failed to surrender root user! Backing out for security!")

# A timer loop that actually controls the humidifier. Used to prevent a
# malicious client from rapidly toggling the state and damaging hardware.
proc runTimer(){.async.} =
  while true:

    if power_on != prev_power:
      echo("Changed state: " & $power_on)
      let pwr_str = if power_on: "1" else: "0"
      discard file_write(pwr_str, GPIO_DIR & "gpio" & USB_POWER & "/value")
      prev_power = power_on

    # Limit how often the check runs
    await sleepAsync(TIMEOUT)

routes:
    get "/":
        resp h1("Moist: IoT Humidifier is ready")

    get "/humidifier":

        let json = %*
            {
                "red_led": cat(GPIO_DIR & "gpio" & RED_LED & "/value"),
                "blue_led": cat(GPIO_DIR & "gpio" & BLUE_LED & "/value")
            }

        resp(json.pretty(), contentType = "application/json")

    post "/humidifier":
        var command = parseJson(request.body)

        let pwr_set = $command["power"].getStr()
        if not isNil(pwr_set):
            if pwr_set == "1" or pwr_set == "0":
                power_on = (pwr_set == "1")
                resp(content="Power value set.",
                     contentType="text/plain")
            else:
                resp(code=Http400,
                     content="Invalid power value (must be 1 or 0)",
                     contentType="text/plain")
        else:
            resp(code=Http400,
                 content="No `power` value specified",
                 contentType="text/plain")

# Start running here
setup()
discard runTimer()
runForever()
