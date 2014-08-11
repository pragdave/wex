class @Readline

    constructor: (@ip, @prompt, @screen) ->
        @history = []
        @search_offset = 0
        @history_offset = 0
        @ip
          .bind('keydown.down',   @next_line)
          .bind('keydown.tab',    @tab_complete)
          .bind('keydown.up',     @previous_line)
          .bind('keydown.Ctrl_g', @exit_search_history)
          .bind('keydown.Ctrl_k', @clear_line)
          .bind('keydown.Ctrl_l', @clear_screen)
          .bind('keydown.Ctrl_n', @next_line)
          .bind("keydown.Ctrl_p", @previous_line)
          .bind('keydown.Ctrl_r', @search_history)

    add_history: (line) ->
        @history.push(line)
        @search_offset = @history_offset = 0


    previous_line: (_ev) =>
        val = @history[@history.length - 1 - @history_offset];
        if val
            @history_offset +=1
        @ip.val(val);
        false


    next_line: (_ev) =>
        val = @history[@history.length + 1 - @history_offset];
        if (val)
            @history_offset -=1
        @ip.val(val);
        false


    clear_line: =>
        @ip.val(@ip.val().slice(0, @ip.caret()))
        
    clear_screen: =>
        @screen.html('')
        

    search_history:  =>
        @ip.autocomplete
            disabled: false
            source:   @autocomplete_history_source()
            close:    =>
                @exit_search_history()
                true
        @original_prompt = @prompt.text()
        @prompt.text("search:")


    get_matching_history: (term) =>
        value for value in @history when value.match(term)


    exit_search_history: =>
        @ip.autocomplete('destroy')
        $('ul.ui-autocomplete').hide()
        @prompt.text(@original_prompt);


    tab_complete: =>
        @original_field = @ip.val()
        @ip.autocomplete
            disabled: false
            source:   @autocomplete_elixir_source()
            response: @check_for_single_element_response
            select:   @append_selection_and_exit
            focus:    @append_selection_to_field
            close:    =>
                @exit_search_history()
                true
            
        @ip.autocomplete('search')
        false

    # We can autocomplete on history or (for tab completion) on
    # elixir names
    autocomplete_history_source: ->
        (request, response) => response(@get_matching_history(request.term))

    autocomplete_elixir_source: ->
        "/api/v1/autocomplete"

    check_for_single_element_response: (event, response) =>
        switch response.content.length
            when 0
                Util.beep(40, 220)
                @ip.autocomplete('disable')
            when 1
                completion = response.content[0].value
                @ip.val(@ip.val() + completion)
                response.content = []
                @ip.autocomplete('disable')
            else
                null

    append_selection_to_field: (event, response) =>
        @ip.val(@original_field + response.item.value)
        event.preventDefault()
        event.stopPropagation()        

    append_selection_and_exit: (event, response) =>
        @append_selection_to_field(event, response)
        @ip.autocomplete('disable')

        

