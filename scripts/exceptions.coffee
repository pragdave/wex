class @Exception

    @format: (msg, formatter) ->
        {s, t, v} = msg
        if t !=  "Tuple" || v.length != 2
            formatter.format(msg)
        else
            [ @format_reason(v[0]), @format_stack(v[1]) ].join("\n")

    @format_reason: (reason) ->
        "<div class='reason'>#{Eval.escape(reason.s)}</div>"

    @format_stack: (stack) ->
        "stack"

    
