class @Help

    constructor: (@ws) ->
        @help_window = $("#help")
        @ws.addHandler "help", @help

    help: (message) =>
        @help_window.html(message.text)
        

