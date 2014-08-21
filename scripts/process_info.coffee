class @ProcessInfo

    constructor: (@rest) ->
        @template = $("#process-info-template .process-info")
        $("#output").on "click", "span.PID", (event) =>
            @handle($(event.target).text())
        
    handle: (pid_as_string) =>
        @rest.get "process_info", pid: pid_as_string, @ok, @failed

    failed: (ev) =>
        alert "Couldn't get process info"

    ok: (data) =>
        process_info = @template.clone()
        new ProcessInfoView(process_info, data)

    
