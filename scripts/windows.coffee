class @Windows

    @layouts: #        horiz      vert (tree/editor)
        layout1:
            show: [ "south" ]
            hide: [ "west", "center" ]
            
        layout2:
            show: [ "south", "center" ]
            hide: [ "west" ]

        layout3:
            show: [ "south", "west", "center" ]
            hide: [ ]

    @handle_click: (event) =>
        console.log "handle click"
        if event.target.type == "radio"
            console.dir event
            @set_layout(event.target.id)

    @set_layout: (layout) =>
        console.log "old layout is #{@current_layout} => #{layout}"
        console.dir @layouts[layout]
        if layout != @current_layout && (to_do = @layouts[layout])

            @show(pane) for pane in to_do.show
            @hide(pane) for pane in to_do.hide
            
            @current_layout = layout
            console.log "new layout is #{layout}"

    @hide: (pane, fast) ->
        if pane == "center"
            @saved_south_size = @layout.state.south.size
            if fast
                @layout.sizePane("south", @layout.state.south.maxSize)
            else
                @animate @saved_south_size, @layout.state.south.maxSize, (val) =>
                    @layout.sizePane("south", val)
        else
            @layout.hide(pane)

    @show: (pane) ->
        if pane == "center"
            @animate @layout.state.south.size, @saved_south_size, (val) =>
                @layout.sizePane("south", val)
        else
            @layout.show(pane)
            
    @setup: ->
        @frame = $('#frame')
        @layout = @frame.layout()
        @hide("center", true)
        @hide("west", true)
        @current_layout = "layout1"
        $("#select-layout").buttonset().on "click", @handle_click    

    @animate: (from, to, fn) ->
        $({foo: from}).animate {foo: to}, 
            step: fn
         
$ ->
    $('#frame')
    .show()
    .layout
        west__size:  0.2
        south__size: 0.35


    
    Windows.setup()
