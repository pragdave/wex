# Simple interface to the file drop API

class @Files
    class @FileDrop

        handlers = []

        @add_handler: (handler) ->
            handlers.push(handler)

        @call_handlers: (files) ->
            handler(files) for handler in handlers

        constructor: (@zone) ->
            @setup_events(@zone)

        drop: (event) =>
            dt = event.dataTransfer || event.originalEvent.dataTransfer
            if !dt
                alert "Dropping files is not supported by this browser"
                return false

            files = dt.files

            if files == null || files == undefined || files.length == 0
                alert "Hmm.. I don't see any files"
                return false

            console.dir(files)

            Files.FileDrop.call_handlers(files)

            event.preventDefault()
            false

        document_drop: (event) =>
            console.log "docdrop"
            event.preventDefault()
            false

        document_enter: (event) =>
            console.log "doc enter"
            event.preventDefault()
            false

        document_over: (event) =>
            console.log "doc over"
            event.preventDefault()
            false

        document_leave: (event) =>
            console.log "doc leave"
            event.preventDefault()
            false

        setup_events: (zone) ->
            zone.on('drop',      @drop)
            $(document)
                .on('drop',      @document_drop)
                .on('dragenter', @document_enter)
                .on('dragover',  @document_over)
                .on('dragleave', @document_leave)
                
