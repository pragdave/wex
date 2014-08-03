class @WsDriver

    constructor: (readyfn) ->
        @handlers = {}
        @ws = new WebSocket("ws://127.0.0.1:8080/ws")
        @ws.onopen = =>
            @ws.onmessage = (event) =>
                @handleMessage(JSON.parse(event.data))
            readyfn(@)

    addHandler: (type, handler) ->
        @handlers[type] = handler
        
    send: (handler, text) ->
        @ws.send(JSON.stringify(msgtype: handler, text: text))


    handleMessage: (message) ->
        callback = @handlers[message.type]
        if callback
            callback(message)
        else
            alert "Unhandled message: " + message.type
