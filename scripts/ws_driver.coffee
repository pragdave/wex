class @WsDriver

    constructor: (readyfn) ->
        @handlers = {}
        if true
            @ws = new WebSocket("ws://127.0.0.1:8080/ws")
            @ws.onopen = =>
                console.log
                @ws.onmessage = (event) =>
                    @handleMessage(JSON.parse(event.data))
                readyfn(@)

            window.onbeforeunload =  =>
                console.log("CLOSING WS")
                @ws.onclose = -> {}
                @ws.close()
        else
            readyfn(@)

    addHandler: (type, handler) ->
        @handlers[type] = handler
        
    send: (handler, text) ->
        if @ws
            @ws.send(JSON.stringify(msgtype: handler, text: text))


    handleMessage: (message) ->
        console.log "Received ws message"
        console.dir(message)
        callback = @handlers[message.type]
        if callback
            callback(message)
        else
            alert "Unhandled message: " + message.type
