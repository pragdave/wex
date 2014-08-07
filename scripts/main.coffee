$ ->
    new WsDriver (ws) ->
        new Eval(ws)
        new Help(ws)
        new Files.Dir(ws, $("#filetree"))
        
    window.editor = new Editor()

