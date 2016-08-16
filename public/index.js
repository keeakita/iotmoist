$(function() {
    "use strict";

    function updateLED() {
        return $.getJSON('/humidifier').done(function(json) {
            if (json.red_led) {
                $('#button-led').css("fill", "#e55");
            } else if (json.blue_led) {
                $('#button-led').css("fill", "#7af");
            } else {
                $('#button-led').css("fill", "white");
            }
        }).fail(function() {
            // TODO: Something
        });
    }

    // Set a timer to update the LED periodically
    // TODO: Maybe use long polling or web sockets instead?
    window.setInterval(function() {
        updateLED();
    }, 1500);

    // Update the LEDs right now, on page load
    updateLED();
});
