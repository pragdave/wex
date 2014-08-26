class @Eval

    constructor: (@ws, rest) ->
        @ip     = $("#input-field")
        @op     = $("#output")
        @prompt = $("#prompt")
        @pane   = $("#interaction")
        
        @ws.addHandler "eval_ok",      @eval_ok
        @ws.addHandler "eval_partial", @eval_partial
        @ws.addHandler "stdout",       @eval_stdout
        @ws.addHandler "stderr",       @eval_stderr
        @ws.addHandler "exception",    @eval_exception

        @readline = new Readline @ip, @prompt, @op, rest

        @formatter = new ValueFormatter(@op)
        
        @ip.parents('form').on "submit", @inputAvailable
        @ip.focus()
        @ws.send "eval", "\"Wex \#{System.version}\""
    
    inputAvailable: (ev) => 
        val = @ip.val()
        @readline.add_history(val)
        prompt = @prompt.html()
        @op.append "<div class=\"iprompt\">#{prompt}</div>
                    <div class=\"ip\">#{Eval.escape(val)}</div>"
        @ip.val ""
        WexEvent.trigger(WexEvent.exception_clear_all)
        @ws.send "eval", val
        ev.preventDefault()
        ev.stopPropagation()
        false

    eval_ok: (message) =>
        @prompt.html("wex>")
        @op.append(@formatter.format(message.text))
        @make_output_visible()        

    eval_partial: (message) =>
        @prompt.html("<span style=\"visibility: hidden\">wex</span>&#x22ee;")

    eval_stdout: (message) =>
        @prompt.html("wex>")
        @write "<div class=\"stdout\">#{Eval.escape(message.text)}</div>"
        
    eval_stderr: (message) =>
        @prompt.html("wex>")
        @write "<div class=\"stderr\">#{Eval.escape(message.text)}</div>"

    eval_exception: (message) =>
        @prompt.html("wex>")
        msg = Exception.format(message.text, @formatter)
        @write "<div class=\"exception\">#{msg}</div>"

    write: (msg) ->
        @op.append msg
        @make_output_visible()
        
    make_output_visible: ->
        @pane.scrollTop(@pane[0].scrollHeight)
        
    @escape: (message) ->
        $('<div/>').text(message).html()

