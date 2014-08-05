class @Eval

    constructor: (@ws) ->
        @ip     = $("#input")
        @op     = $("#output")
        @prompt = $("#prompt")
        
        @ws.addHandler "eval_ok",      @eval_ok
        @ws.addHandler "eval_partial", @eval_partial
        @ws.addHandler "stdout",       @eval_stdout
        @ws.addHandler "stderr",       @eval_stderr

        @readline = new Readline @ip, @prompt
        
        @ip.parent('form').on "submit", @inputAvailable
        @ip.focus()
    
    inputAvailable: (ev) => 
        val = @ip.val()
        @readline.add_history(val)
        prompt = @prompt.html()
        @op.append "<div class=\"ip\">#{prompt} #{val}</div>"
        @ip.val ""
#        @ws.send "eval", val
        ev.preventDefault()
        ev.stopPropagation()
        false

    eval_ok: (message) =>
        @prompt.html("wex>")
        @op.append "<div class=\"value\">#{message.text}</div>"

    eval_partial: (message) =>
        @prompt.html("...>")

    eval_stdout: (message) =>
        @op.append "<div class=\"stdout\">#{message.text}</div>"
        
    eval_stderr: (message) =>
        @op.append "<div class=\"stderr\">#{message.text}</div>"
        

