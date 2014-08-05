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
