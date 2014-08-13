class @Eval

    constructor: (@ws) ->
        @ip     = $("#input-field")
        @op     = $("#output")
        @prompt = $("#prompt")
        @pane   = $("#interaction")
        
        @ws.addHandler "eval_ok",      @eval_ok
        @ws.addHandler "eval_partial", @eval_partial
        @ws.addHandler "stdout",       @eval_stdout
        @ws.addHandler "stderr",       @eval_stderr

        @readline = new Readline @ip, @prompt, @op
        
        @ip.parents('form').on "submit", @inputAvailable
        @ip.focus()
        @ws.send "eval", "\"Wex \#{System.version}\""
    
    inputAvailable: (ev) => 
        val = @ip.val()
        @readline.add_history(val)
        prompt = @prompt.html()
        @op.append "<div class=\"iprompt\">#{prompt}</div>
                    <div class=\"ip\">#{@escape(val)}</div>"
        @ip.val ""
        @ws.send "eval", val
        ev.preventDefault()
        ev.stopPropagation()
        false

    eval_ok: (message) =>
        @prompt.html("wex>")
        @write "<div class=\"value\">#{@escape(message.text)}</div>"

    eval_partial: (message) =>
        @prompt.html("<span style=\"visibility: hidden\">wex</span>&#x22ee;")

    eval_stdout: (message) =>
        @prompt.html("wex>")
        @write "<div class=\"stdout\">#{@escape(message.text)}</div>"
        
    eval_stderr: (message) =>
        @prompt.html("wex>")
        @write "<div class=\"stderr\">#{@escape(message.text)}</div>"

    write: (msg) ->
        @op.append msg
        @pane.scrollTop(@pane[0].scrollHeight)
        
    escape: (message) ->
        $('<div/>').text(message).html()

