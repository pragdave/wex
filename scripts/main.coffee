$ ->

    rest = new RestDriver("v1")
    
    new WsDriver (ws) ->
        new Eval(ws, rest)
        new Help(ws)
        
        mydir  = new Files.DirList(ws, rest)
        myfile = new Files.FileLoader(rest)
        new Files.DirView($("#filetree"), mydir)

        new EditorFileListView(EditorFileList)

        editor = new Editor(myfile, rest, ws).editor
        editor.setTheme("ace/theme/solarized_light")

#        mydir.get_listing("/Users/dave/Play/wex/lib")
