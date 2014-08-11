class @Files.File

    constructor: (@rest) ->

    load: (path, ok, failed) ->
        @rest.get("file/load", { path: path }, ok, failed)

        

    
