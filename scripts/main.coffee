$ ->

    rest = new RestDriver("v1")
    
    new WsDriver (ws) ->
        new Eval(ws)
        new Help(ws)
        window.mydir = new Files.Dir(ws, rest)
        window.myfile = new Files.File(rest)
        new Files.DirView($("#filetree"), window.mydir)
        window.editor = new Editor(window.myfile)

        new EditorFileListView(EditorFileList)
        window.mydir.get_listing("/Users/dave/Play/wex/lib")
