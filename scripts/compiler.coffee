class @Compiler

    constructor: (@ws, @rest, @editor, @ace) ->
        @bind_keys(@ace)
        @ws.addHandler("compile_stderr", @compilation_errors)

    #######################
    # Trigger compilation #
    #######################
    
    compile_file_from_keystroke: (event) =>
        event.preventDefault()
        @ace_compile_file()
        
    compile_file: () =>
        lines = @ace
                .getSession()
                .getDocument()
                .getAllLines()
        console.dir(lines)
        @editor.clear_all_errors()
        @ws.send "compile", lines.join("\n")

    #############
    # Show help #
    #############

    help: (editor) =>
        session = editor.getSession()
        cursor  = editor.getCursorPosition()
        match   = Util.beginning_of_line_to_point(session, cursor)
        if match
            @rest.get "get_help", {term: match}, @h1, @h2

    h1: ->
        console.log "h1"
            
    h2: ->
        console.log "h2"
            
        
    ############################################
    # Handle compilation errors that come back #
    ############################################
    
    compilation_errors: (errors) =>
        console.log("Errors")
        console.dir(errors)
        body = errors.text
        switch $.type(body)
            when "array"
                @editor.record_error(@nested_error(error)) for error in body
            else
                @editor.record_error(@maybe_translate(body))
                

    ###########
    # Utility #
    ###########

    bind_keys: ->
        $(window)
            .bind('keydown.Meta_s', @compile_file_from_keystroke)

        @ace.commands.addCommand
            name: 'compile',
            exec: @compile_file
            bindKey: 
                win: 'Ctrl-B'
                mac: 'Command-B'
                sender: 'editor|cli'

        @ace.commands.addCommand
            name: 'help',
            exec: @help
            bindKey: 
                win: 'Ctrl-S'
                mac: 'Command-H'
                sender: 'editor|cli'


    # The server can send us error maps or plain strings. If the latter,
    # try to translate into a map
    
    maybe_translate: (error) ->
        switch
            when $.type(error) == "object"
                error
            when match = error.match(/^\*\*\s\([^)]+\)\s+([^:]+):(\d+):\s(.*)/)
                file:  match[1]
                line:  match[2]
                error: match[3]
                type:  "warning"
            when match = error.match(/^([^:]+):(\d+):\s(.*)/)
                file:  match[1]
                line:  match[2]
                error: match[3]
                type:  "warning"
            else
                error        
            
    # Some errors contain the actual line number in the text of the error
    # Go figure
    
    nested_error: (error) ->
        text = error.error
        switch
            when match = text.match(/^\*\*\s\(([^)]+)\)\s+([^:]+):(\d+):\s(.*)/)
                file:  match[2]
                line:  match[3]
                error: "#{match[1]}: #{match[4]}"
                type:  if /error/i.test(match[1]) then "error" else "warning"
            when match = text.match(/^([^:]+):(\d+):\s(.*)/)
                file:  match[1]
                line:  match[2]
                error: match[3]
                type:  "warning"
            else
                error        


