class @Exception

    source   = $("#exception-template").html()
    template = Handlebars.compile(source)

    @format: (msg, formatter) ->
        console.log "BOOM"
        console.dir msg
        {s, t, v} = msg
        
        if t !=  "Tuple" || v.length != 2
            formatter.format(msg)
        else
            reason = v[0].v
            stack  = v[1].v
            @notify_files_they_have_a_stacktrace(stack)
            @format_stack(reason, stack)

    @notify_files_they_have_a_stacktrace: (stack) ->
        for frame, level in stack
            raw_frame = frame.v.frame.v
            location  = raw_frame[3].v
            file      = location.file.s
            line      = parseInt(location.line.s)
            WexEvent.trigger(WexEvent.exception_line, file, line, level)
        
    @format_stack: (reason, stack) ->
        stack_data =
            reason: reason
            trace:  @trace(stack)
        template(stack_data)

    @trace: (stack) ->
        (@format_frame(frame, @prefix(n)) for frame, n in stack)
    
    @format_frame: (frame, prefix) ->
        actual = frame.v
        prefix:   prefix
        mfa:      actual.mfa.s
        location: actual.location.s

    @prefix: (n) ->
        if n == 0 then "at" else "from"
