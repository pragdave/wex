class @EditorFileListView

    constructor: (@model) ->
        @tabs         = $("#tabs")
        @tab_list     = @tabs.find("#tab-list")
        @current_file = null
        @add_tab_click_handler()
        
        WexEvent.handle(WexEvent.filelist_updated,
                       "EditorFileListView",
                       @update_file_list)
        WexEvent.handle(WexEvent.filelist_select,
                       "EditorFileListView",
                       @select_file_list_entry)
        WexEvent.handle(WexEvent.exception_in_file,
                       "EditorFileListView",
                       @exception_in_file)

    update_file_list: (event, index, file) =>
        li = $("<li><a href=\"#ace\">#{file.name}</a></li>")
        li.data("file", file)
        @tab_list.append(li)
        @select(li)

    tab_clicked: (event) =>
        li = $(event.target).parent('li')
        @select(li)
        event.preventDefault()

    select: (li) ->
        @current_file = li.data("file")
        li.addClass('active').siblings().removeClass('active')
        WexEvent.trigger(WexEvent.open_file_in_editor, @current_file)
        
    select_file_list_entry: (event, index, file) =>
        @select($(@tab_list.find('li')[index]))

    add_tab_click_handler: ->
        @tab_list.on "click", "a", @tab_clicked

    exception_in_file: (event, file, line, level) =>
        if file == @current_file
            WexEvent.trigger(WexEvent.show_exception_in_editor,
                line, level)
            
