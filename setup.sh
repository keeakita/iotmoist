#!/bin/bash

if [ $EUID -ne 0 ]; then
    echo "This script should be run as root."
    exit 1
fi

set -e
set -u
set -x

GPIO_DIR="/sys/class/gpio"
RED_LED="10"
BLUE_LED="9"
USB_POWER="15"

# Export devices
echo "$RED_LED" > "$GPIO_DIR"/export
echo "$BLUE_LED" > "$GPIO_DIR"/export
echo "$USB_POWER" > "$GPIO_DIR"/export

# Set directions
echo 'in' > "$GPIO_DIR"/gpio"$RED_LED"/direction
echo 'in' > "$GPIO_DIR"/gpio"$BLUE_LED"/direction
echo 'out' > "$GPIO_DIR"/gpio"$USB_POWER"/direction

# Set initial value
echo '0' > "$GPIO_DIR"/gpio"$USB_POWER"/value

# Grant permissions to set and read values
chown root:gpio "$GPIO_DIR"/gpio{$RED_LED,$BLUE_LED,$USB_POWER}/value
chmod g+rw "$GPIO_DIR"/gpio{$RED_LED,$BLUE_LED,$USB_POWER}/value
