$(function() {
    "use strict";

    var buttonDepressed = false;

    function updateLED() {
        return $.getJSON('/humidifier').done(function(json) {
            if (json.red_led) {
                $('#button-led').css("fill", "#e55");
            } else if (json.blue_led) {
                $('#button-led').css("fill", "#7af");
            } else {
                $('#button-led').css("fill", "white");
            }

            setButtonState(json.has_power);
        }).fail(function() {
            // TODO: Something
        });
    }

    function setButtonState(newState) {
        buttonDepressed = newState;

        if (newState) {
            $('#button').addClass('depressed');
        } else {
            $('#button').removeClass('depressed');
        }
    }

    function buttonClicked() {
        setButtonState(!buttonDepressed);

        // TODO: Error handling
        $.post('/humidifier', JSON.stringify({
            "power": buttonDepressed
        })).done();

        // Prediction: the LED will be blue if depressed or white otherwise.
        // Guess at the LED state for a more fluid UX.
        if (buttonDepressed) {
            $('#button-led').css("fill", "#7af");
        } else {
            $('#button-led').css("fill", "white");
        }
    }

    $('#button').on('click',  buttonClicked);

    // Set a timer to update the LED periodically
    // TODO: Maybe use long polling or web sockets instead?
    window.setInterval(updateLED, 1500);

    // Update the LEDs right now, on page load
    updateLED();
});
