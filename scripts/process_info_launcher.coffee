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

    handle: (pid_as_string) =>
        @rest.get "process_info", pid: pid_as_string, @ok, @failed

    failed: (ev) =>
        alert "Couldn't get process info"

    ok: (data, req) =>
        ProcessTree.add_process_info(req.pid, data)

    
