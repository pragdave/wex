class @Files.File

    constructor: (@name, @full_path) ->
        @id     = @full_path
        @text   = @name
        @errors = []
        @stacktrace = []
        
    load: (path, ok, failed) ->
        @rest.get("file/load", { path: path }, ok, failed)

    # regular errors
    record_error: (error) ->
        @errors.push(error)

    has_errors: ->
        @errors.length > 0

    clear_errors: ->
        @errors = []
        @stacktrace = []

    # stack trace
    record_stack_trace: (line, level) ->
        @stacktrace.push
            line:  line
            level: level

    

    
