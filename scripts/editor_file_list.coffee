class @EditorFileList
    
    @files: []

    @make_active: (file) ->
        if (index = @find_file_index_in_list(file.id)) >= 0
            WexEvent.trigger(WexEvent.filelist_select, index, file)
        else
            EditorFileList.files.push file
            index = EditorFileList.files.length - 1
            WexEvent.trigger(WexEvent.filelist_updated, index, file)

    @find_file_node_in_list: (file_name) ->
        index = @find_file_index_in_list(file_name)
        if index >= 0
            @files[index]
        else
            null
            
    @find_file_index_in_list: (file_name) ->
        result = (i for entry, i in @files when entry.id == file_name)
        if result.length > 0
            result[0]
        else
            -1

    @is_file_in_list: (file_name) ->
        @find_file_index_in_list(file_name) >= 0

    @clear_all_errors: ->
        file.clear_errors() for file in @files
