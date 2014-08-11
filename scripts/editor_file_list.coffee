class @EditorFileList
    
    @files: []

    @make_active: (file) ->
        if (index = @find_file_index_in_list(file)) >= 0
            WexEvent.trigger(WexEvent.filelist_select, index, file)
        else
            EditorFileList.files.push file
            index = EditorFileList.files.length - 1
            WexEvent.trigger(WexEvent.filelist_updated, index, file)

    @find_file_index_in_list: (file) ->
        result = (i for entry, i in @files when entry.id == file.id)
        if result.length > 0
            result[0]
        else
            -1

    @find_file_in_list: (file) ->
        @find_file_index_in_list(file) >= 0
