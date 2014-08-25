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
            @format_stack(v[1].v, v[0].v)

    @format_stack: (stack, reason) ->
        stack_data =
            reason: reason
            trace:  @trace(stack)
        template(stack_data)

    @trace: (stack) ->
        (@format_frame(frame, @prefix(n)) for frame, n in stack)
    
    @format_frame: (frame, prefix) ->
        if frame.t == "Map"
            @format_override(frame)
        else
            @format_regular_frame(frame, prefix)

    @format_override: (frame) ->
        override: frame.v.override

        
    @format_regular_frame: (frame, prefix) ->
        [ m, f, a, l ] = frame.v
        if a.t == "List"
            @format_call(m, f, a, l, prefix)
        else
            m:        m.s
            f:        @remove_leading_colon(f.s)
            a:        a.s
            location: @format_location(l)
            prefix:   prefix

    @format_call: (m, f, a, l, prefix) ->
            m:        m.s
            f:        @remove_leading_colon(f.s)
            a:        a.s
            location: @format_location(l)
            prefix:   prefix
        
        
    @format_location: (loc) ->
        if loc.t == "List" && loc.v.length == 0
            ""
        else
            "#{@remove_quotes(loc.v.file.s)}:#{loc.v.line.s}"
    
    @prefix: (n) ->
        if n == 0 then "at" else "from"

    @remove_leading_colon: (str) ->
        if str.startsWith(":")
            str.substr(1)
        else
            str

    @remove_quotes: (str) ->
        str.substr(1, str.length-2)
        

    
