class @ProcessInfoLauncher

    constructor: (@rest) ->
        @register_handler($("#output"))
        WexEvent.handle(WexEvent.process_info_created,
                        "ProcessInfoLauncher",
                        @new_window)
                            

    register_handler: (element) ->
        element.on "click", "span.pid", (event) =>
            @handle($(event.target).text())

    new_window: (event, win) =>
        @register_handler(win)

    update: (pid_as_string, view) =>
        @rest.get "process_info", pid: pid_as_string, @ok, @failed, view
        
    handle: (pid_as_string) =>
        @rest.get "process_info", pid: pid_as_string, @ok, @failed

    failed: (ev) =>
        alert "Couldn't get process info"

    ok: (data, req, view) =>
        if view
            view.update(this, req.pid, data)
        else
            ProcessTree.add_process_info(this, req.pid, data)
    
