import jester, asyncdispatch, htmlgen, streams, json, os

const
    # GPIO directory
    GPIO_DIR = "/sys/class/gpio/"

    # Input pins
    RED_LED   = "24"
    BLUE_LED  = "23"

    # Ouput pins
    USB_POWER = "27"

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
                if file_write(pwr_set, GPIO_DIR & "gpio" & USB_POWER & "/value"):
                    resp(content="Power value set.",
                         contentType="text/plain")
                else:
                    resp(code=Http500,
                         content="Could not set power value",
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
runForever()
