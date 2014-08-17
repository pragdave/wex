class @Util
    @beep: (duration, freq) ->
        @ctx ||= new (window.AudioContext || window.webkitAudioContext)()

        duration = +duration
        osc = @ctx.createOscillator()
        osc.type = 0
        osc.frequency.value = freq
        osc.connect(@ctx.destination)
        osc.noteOn(0)

        done = => osc.noteOff(0)
        setTimeout(done, duration)


    @reverse_string: (text) ->
        text.split('').reverse().join('')        

    # return the current editor line up to the end of the word containing point
    @beginning_of_line_to_point: (session, point) ->
        range     = session.getWordRange(point.row, point.column)
        range.start.column = 0
        text      = session.getTextRange(range)
        @find_something_to_complete(text)
        
    @find_something_to_complete: (text) ->
        console.log "Autocomplete = '#{text}'"
        backwards = Util.reverse_string(text)
        match     = backwards.match(/^[!?.]?[a-zA-Z0-9_]+(\.[a-zA-Z0-9]*([A-Z]|[a-z]))*:?/)
        console.dir match
        if match
           Util.reverse_string(match[0])
        else
            false
    
