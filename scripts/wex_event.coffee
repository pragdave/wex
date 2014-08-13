class @WexEvent

    @dirlist_updated     = "wex.dirlist_updated"
    @filelist_select     = "wex.filelist_select"
    @filelist_updated    = "wex.filelist_updated"
    @load_file           = "wex.load_file"
    @open_file_in_editor = "wex.open_file_in_editor"
    @update_errors       = "wex.update_errors"
        
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
            


$ ->
    window.EventCentral = $(window)
