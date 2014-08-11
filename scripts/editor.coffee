class @Editor

    constructor: (@file_loader) ->
        @editor = ace.edit("ace")
        @editor.setTheme("ace/theme/monokai")
#        @session = @editor.getSession()
#        @session.setMode("ace/mode/elixir")
        WexEvent.handle(WexEvent.load_file,           "Editor", @load_file)
        WexEvent.handle(WexEvent.open_file_in_editor, "Editor", @open_file)

    load_file: (event, node) =>
        if EditorFileList.find_file_in_list(node)
            EditorFileList.make_active(node)
        else
            @file_loader.load(node.id,
                ((file) => @load_ok(file, node)),
                @load_failed)

    load_ok: (file, node) =>
        console.log "load ok"
        console.dir file
        if file.status == "ok"
            node.content = file.content
            node.document = ace.createEditSession(node.content, "ace/mode/ruby")
            console.log "loaded"
            EditorFileList.make_active(node)
        else
            alert "Couldn't load #{file.path}: #{file.message}"
            
    load_failed: (event) =>
        console.log "failed"
        console.dir event

    open_file: (event, file) =>
        @editor.setSession file.document
