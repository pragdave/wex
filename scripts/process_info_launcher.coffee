class @ProcessInfoLauncher

    constructor: (@rest) ->
        $("#output").on "click", "span.pid", (event) =>
            @handle($(event.target).text())
        
    handle: (pid_as_string) =>
        @rest.get "process_info", pid: pid_as_string, @ok, @failed

    failed: (ev) =>
        alert "Couldn't get process info"

    ok: (data, req) =>
        new ProcessInfoView(req.pid, data)

    
