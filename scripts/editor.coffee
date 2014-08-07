class @Editor

    constructor: ->
        @editor = ace.edit("ace")
        @editor.setTheme("ace/theme/monokai")
        @session = @editor.getSession()
#        @session.setMode("ace/mode/elixir")
