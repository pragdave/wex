$ ->

    # Yes, I could use a DI framework. I could spend a week learning
    # the various wrinkles and dependencies, and worrying about what
    # version to use, and so on.  Or I could write this...

    
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

        new ProcessInfoLauncher(rest)

#        mydir.get_listing("/Users/dave/Play/wex/lib")
