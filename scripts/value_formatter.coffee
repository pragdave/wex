class @ValueFormatter

    # The server sends us Elixir values as tagged data structures—it
    # takes the potentially nested original value and turns every value
    # into a `%{ t: type, v: value, s: string-representation }`.


    format: (obj) ->
        res = @format_obj(obj)
        if $.type(res) == "string"
            "<div class='value'>#{res}</div>"
        else
            @wrap_in_tree_widget(res)

    format_to_string: (obj) ->
        res = @format(obj)
        if $.type(res) != "string"
            res[0].outerHTML
        else
            res
        
    format_obj: (obj) ->
        {s,t,v} = obj
        if t == "Struct"
            console.log s
        res = switch
            when t == "String" then @e(v)
            when s.length < 60 then @format_inline(obj)
            else @obj_to_tree(obj)
        console.log "Format.. #{s}"
        console.dir obj
        console.log "becomes"
        console.dir res
        res

    format_inline: (obj) ->
        if $.type(obj.v) == "string"
            @html_value(obj)
        else
            @inline_container(obj)

    wrap_in_tree_widget: (nodes) ->
        tree = $("<div class='object-tree'></div>")
        setTimeout (=> @create_jstree(tree, nodes)), 50
        tree
        
    create_jstree: (tree, nodes) ->
        console.dir nodes
        tree.jstree
            core:
                data:   [ nodes ]
                worker: false
                themes:
                    stripes: true
#            autoEscape: false
#            autoOpen:   false
#            selectable: false

        tree.bind "open_node.jstree", @set_key_widths


    inline_container: (obj) ->
        {s,t,v} = obj
        switch t
            when "CharList"
                list = (val.v for val in v).join(",")
                "#{s} <span class='csize'>([#{list}])</span>"

            when "List"
                @wrap_list_container("[", v, "]")

            when "Tuple"
                if @is_mfa(obj)
                    @format_mfa(obj)
                else
                    @wrap_list_container("{", v, "}")

            when "Struct"
                @wrap_map_container("%#{obj.str}{", v, "}")

            when "Map"
                @wrap_map_container("%{", v, "}")

            when "KW list"
                @wrap_map_container("[", v, "]")

            else
                alert "Can't wrap #{t}"

    wrap_list_container: (start, list, end) ->
        content = (@format_inline(obj) for obj in list)
        start + content.join(", ") + end

    wrap_map_container:  (start, map, end) ->
        content = if Array.isArray(map)
                      (@format_kv_non_atom(item) for item in map)
                  else
                      (@format_kv(key, value) for key, value of map)
                      
        start + content.join(", ") + end

    format_kv: (key, value) ->
        if $.type(key) == "string"
            @remove_colon_from_atom(key) + ": " + @format_inline(value)
        else
            @format_inline(key) + " => " + @format_inline(value)
            
    format_kv_non_atom: (item) ->
        if item.t == "Tuple" && item.v.length == 2
            @format_inline(item.v[0]) + " => " + @format_inline(item.v[1])
        else
            @format_inline(item)
            
            
        


    obj_to_tree: (obj) ->
        switch $.type(obj.v)
            when "string"
                text: @html_value(obj)
            else
                @format_container(obj)

    format_container: (obj) ->
        {s,t,v} = obj
        switch
            when @is_mfa(obj)
                @format_mfa(obj)
            else
                text:     @container_label(obj)
                children: @render_children(v)

    render_children: (v) ->
        if Array.isArray(v)
            (@format_obj(child) for child in v)
        else
            (@format_pair(key, child) for key, child of v)
            

    is_mfa: (obj) ->
        v = obj.v
        obj.t == "Tuple" &&
        v.length == 3    &&
        v[0].t == "atom" &&
        v[1].t == "atom" &&
        v[2].t == "integer"

    format_mfa: (obj) ->
        [m,f,a] = obj.v
        mod = m.v
        mod = mod.substr(8) if mod.startsWith(":Elixir.")
        fun = @remove_colon_from_atom(f.v)
        "#{mod}.#{fun}/#{a.v}"

    html_value: (obj) ->
        "<span class='#{obj.t}' title='#{obj.t}'>#{@e(obj.v)}</span>"

    container_label: (obj) ->
        value = @container_label_text(obj)
        klass = obj.t.replace(/\s/, "_")
        "<span class='#{klass}' title='#{obj.t}'>#{value}</class>"

    container_label_text: (obj) ->
        size =  "#{Object.keys(obj.v).length} entries"
        switch obj.t
            when "List"
                if obj.v == "[]"
                    "[ ]"
                else
                    "[…#{size}…]"
            when "CharList"
                "#{@e(obj.s)} <span class='csize'>(#{obj.v.length} chars)</span>"
            when "Struct"
                "%#{obj.str}{…#{size}…}"
            when "Map"
                "%{…#{size}…}"
            when "Tuple"
                "{…#{size}…}"
            when "KW list"
                "[…kw_size: #{size}…]"
            else
                "#{obj.t} <span class='csize'>(#{size})</span>"


    format_pair: (left, right) ->
       if right.s.length > 40 && $.type(right.v) != "string"
           right_label = @container_label(right)
           text:     @pair_label(@e(left), right_label)
           children: @render_children(right.v)
       else
           text:     @pair_label(@e(left), @format_inline(right))


    pair_label: (left, right) ->
      "<div class='pair-left-wrapper'><span class='pair-left'>#{left}</span></div> " +
      "<span class='pair-right'>#{right}</span>"
        
    remove_colon_from_atom: (atom) ->
        if atom.startsWith(":")
            atom.substr(1)
        else
            atom
            

    e: Eval.escape
               

    # Go through the tree looking for keyword lists. For each, look at the keys in
    # the children, setting the width of each to something consistent.
    
    set_key_widths: (event, tree) =>
        node = $("##{tree.node.id}")
        @set_key_width($(kw_list)) for kw_list in node.find("ul")
    
    set_key_width: (child_tree) ->
        keys = child_tree.find("span.pair-left")
        widths = ($(key).width() for key in keys)
        max = Math.max.apply(Math, widths)
        if max > 0
            @add_leader($(key), max + 20) for key in keys 
    
    add_leader: (key, width) ->
        holder = $(key).parent("div.pair-left-wrapper")
        holder.width width


# Find a home for this
# 
$ ->
    $.jstree.defaults.core.themes.icons = false    
