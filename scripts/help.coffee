class @Help

    constructor: (@ws) ->
        @help_window = $("#help")
        @help_window.dialog
            autoOpen:  false
            modal:     false
            position:  { my: "right top", at: "right-5% top-10%", of: window }
            width:     $(window).width()*0.4
            maxHeight: $(window).height()*0.75
            
        @ws.addHandler "help", @help

    help: (message) =>
        @help_window.html(message.text)
        @help_window.dialog("open")
        

