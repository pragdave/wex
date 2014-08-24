class @ProcessTree

    all_processes = {}


    @add_process_info: (launcher, pid, data, div) ->
        unless all_processes[pid] && false   # for now, always show
            popup = new ProcessInfoView(launcher, pid, data, div)
            all_processes[pid] = popup

    @delete_process: (event, pid) =>
        console.log "ProcessTree.delete #{pid}"
        delete all_processes[pid]


    WexEvent.handle(WexEvent.process_info_closed,
                    "ProcessTree",
                    ProcessTree.delete_process)

