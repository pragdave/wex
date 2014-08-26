class @Editor

    constructor: (@file_loader, @rest, @ws) ->
        @create_ace_editor()
        @current_file = null
        @compiler     = new Compiler(@ws, @rest, @, @editor)
        @displayed_exceptions = []

        WexEvent.handle(WexEvent.load_file,           "Editor", @load_file)
        WexEvent.handle(WexEvent.open_file_in_editor, "Editor", @open_file)
        WexEvent.handle(WexEvent.show_exception_in_editor, "Editor", @note_exception)
        WexEvent.handle(WexEvent.exception_clear_all,      "Editor", @remove_exceptions)

        @create_sandbox()

    create_ace_editor: ->
        language = ace.require("ace/ext/language_tools")
        @range  = ace.require("ace/range")
        @editor = ace.edit("ace")
        @editor.setTheme("ace/theme/monokai")
        session = @editor.getSession()
        session.setMode("ace/mode/elixir")
        @editor.setOptions
            enableBasicAutocompletion: true
#            enableLiveAutocompletion:  true
            
        new EditorCompletion(@rest, language)

    load_file: (event, file_node) =>
        if EditorFileList.is_file_in_list(file_node.id)
            EditorFileList.make_active(file_node)
        else
            @file_loader.load(file_node.id,
                ((file_from_server) => @load_ok(file_from_server, file_node)),
                @load_failed)

    load_ok: (file_from_server, file_node) =>
        console.dir file
        if file_from_server.status == "ok"
            @edit(file_node, file_from_server.content)
        else
            alert "Couldn't load #{file_from_server.path}: #{file_from_server.message}"
            
    load_failed: (event) =>
        console.log "failed"
        console.dir event

    edit: (file_node, content) ->
        file_node.content  = content
        file_node.document = ace.createEditSession(content, "ace/mode/elixir")
        EditorFileList.make_active(file_node)
        
    open_file: (_event, file) =>
        @editor.setSession file.document
        @current_file = file
        @add_errors(file)
        @compile_on_changes()

    record_error: (error) ->
        if file = EditorFileList.find_file_node_in_list(error.file)
            file.record_error(error)
            if file == @current_file
                @add_errors(file)
        else
            alert "Cannot record error for #{error.file}"
        
    clear_all_errors: =>
        EditorFileList.clear_all_errors()
        @editor
        .getSession()
        .clearAnnotations()

    add_errors: (file) ->
        annotations = (@annotation_for(error) for error in file.errors)
        @editor
        .getSession()
        .setAnnotations(annotations)

    annotation_for: (error) ->
        if error.line == 0
            error.line = @editor
                        .getSession()
                        .getDocument()
                        .getLength()
                        
        { row: error.line - 1, type: error.type || "error", text: error.error }
        
    create_sandbox: ->
        sandbox = new Files.File("wex sandbox", "wex sandbox")
#        @edit(sandbox, "# This is the sandbox. Have fun!")
        @edit(sandbox, """
        defmodule A do
          def b(c,d) do
              c/d
          end
        end
        """)
        @editor.selectAll()

    compile_on_changes: ->
        @editor.session.on "change", @reset_timer
        @trigger_compilation()

    set_timer: =>
        @timer = setTimeout @trigger_compilation, 600

    reset_timer: =>
        clearTimeout @timer
        @set_timer()

    trigger_compilation: =>
        @compiler.compile_file()

    # this is for when we switch files
    add_exceptions_from_file: =>
        session = @editor.getSession()
        for line, level in @current_file.stacktrace
            add_exception(session, line-1, level) 

    # and this is when an exception comes in when code is run
    note_exception: (event, line, level) =>
        console.dir [ line, level ]
        line -= 1
        range = new @range.Range(line, 0, line, 1000)
        @editor.navigateTo(line, 0)
        @add_exception(@editor.getSession(), line, level)

    add_exception: (session, line, level) =>
        class_name = "exception-level l#{level}"
        session.addGutterDecoration(line, class_name)
        @displayed_exceptions.push [line, class_name]

    remove_exceptions: =>
        session = @editor.getSession()
        for [line, class_name] in @displayed_exceptions
            session.removeGutterDecoration(line, class_name)


