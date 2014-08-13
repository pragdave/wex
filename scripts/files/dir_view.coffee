class @Files.DirView

    constructor: (@tree, @model) ->
        WexEvent.handle(WexEvent.dirlist_updated,     "DirView", @dirlist_updated)
        WexEvent.handle(WexEvent.open_file_in_editor, "DirView", @file_selected)
        @tree.tree
            data:     []
            autoOpen: 1

    dirlist_updated: (event) =>
        result = @add_entry(@model.tree, {})
        @tree.tree('loadData', [ result ])
        @tree.on 'tree.click', @tree_click


    tree_click: (event) =>
        if event.node.type == "file"
            WexEvent.trigger(WexEvent.load_file, event.node)

    file_selected: (event, file) =>
        node = @tree.tree('getNodeById', file.id)
        @tree.tree('selectNode', node)

    ###########
    # Helpers #
    ###########
    
    add_entry: (entry, container) ->
        name = if entry.relative_path == ""
                   entry.full_path
               else
                   entry.relative_path
                   
        if entry.type == "dir"
            node = new Files.Dir(name,
                                 full_path,
                                 children_of(entry.entries))
        else
            node = new Files.file(name, full_path)

        node
        
    children_of: (tree) ->
        (@add_entry(entry, container) for entry in tree)

           
