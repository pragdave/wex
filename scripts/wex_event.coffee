class @WexEvent

    @dirlist_updated      = "wex.dirlist_updated"
    @filelist_select      = "wex.filelist_select"
    @filelist_updated     = "wex.filelist_updated"
    @load_file            = "wex.load_file"
    @open_file_in_editor  = "wex.open_file_in_editor"
    @update_errors        = "wex.update_errors"
    @process_info_created = "wex.process_info_created"
    @process_info_closed  = "wex.process_info_closed"
    @exception_in_file    = "wex.exception_in_file"
    @exception_line       = "wex.exception_line"
    @exception_clear_all  = "wex.exception_clear_all"
    @show_exception_in_editor = "wex.show_exception_in_editor"
    
    window.EventCentral = $(window)

    @trigger: (name, args...) ->
        console.log("Trigger #{name}")
        EventCentral.trigger(name, args)

    @handle: (name, klass, fun) ->
        console.log("#{name} handled by #{fun}")
        EventCentral.on name, (event, args...) =>
            console.log "forward #{name} → #{klass} passing:"
            console.dir args
            if args
                fun(event, args...)
            else
                fun(event)
            


