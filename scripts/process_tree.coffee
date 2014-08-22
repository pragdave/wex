class @ProcessTree

    all_processes = {}


#    WexEvent.handle(WexEvent.process_info_created,
#                    "ProcessTree",
#                    @new_window)


    @add_process_info: (pid, data) ->
        unless all_processes[pid]
            popup = new ProcessInfoView(pid, data)
            all_processes[pid] = popup

    @delete_process: (event, pid) =>
        console.log "ProcessTree.delete #{pid}"
        delete all_processes[pid]


    WexEvent.handle(WexEvent.process_info_closed,
                    "ProcessTree",
                    ProcessTree.delete_process)

