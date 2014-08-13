class @Files.FileLoader

    constructor: (@rest) ->

    load: (path, ok, failed) ->
        @rest.get("file/load", { path: path }, ok, failed)

        

    
