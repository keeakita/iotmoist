$(function() {
    "use strict";

    window.setInterval(function() {
        $.getJSON('/humidifier').done(function(json) {
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
    }, 1500);


});
