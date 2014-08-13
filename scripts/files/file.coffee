class @Files.File

    constructor: (@name, @full_path) ->
        @id     = @full_path
        @label  = @name
        @errors = []
        
    load: (path, ok, failed) ->
        @rest.get("file/load", { path: path }, ok, failed)

    record_error: (error) ->
        @errors.push(error)

    has_errors: ->
        @errors.length > 0

    clear_errors: ->
        @errors = []
        

    
