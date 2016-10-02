$(function() {
    "use strict";

    var buttonDepressed = false;
    var updateTimer = undefined;

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

    function startUpdateTimer() {
        if (updateTimer !== undefined) {
            window.clearInterval(updateTimer);
        }
        updateTimer = window.setInterval(updateLED, 1500);
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

        // Stop the update timer and only update it after the POST to prevent
        // "bouncing" of the button.
        if (updateTimer !== undefined) {
            clearInterval(updateTimer);
            updateTimer = undefined;
        }

        // TODO: Error handling
        $.post('/humidifier', JSON.stringify({
            "power": buttonDepressed
        })).done(function() {
            // Restart the timer
            startUpdateTimer();
        });

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
    startUpdateTimer();

    // Update the LEDs right now, on page load
    updateLED();

    // Start a tour if this is the user's first visit
    var tour = new Tour({
        steps: [{
            element: '#button-led',
            title: 'LED Indicator',
            content: "Blue means the humidifier is on. Red means it needs the filter changed. White means it's off.",
            placement: 'auto left'
        },
        {
            element: '#button',
            title: 'Power Button',
            content: 'This turns the power off and on.',
            placement: 'auto top'
        }]
    });

    tour.init();
    tour.start();
});
