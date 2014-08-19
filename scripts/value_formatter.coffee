class @ValueFormatter

    constructor: (@op) ->
        @id = 1000
        
    format: (obj) ->
        switch
            when $.type(obj) == "string"
                @write_value(@e(obj))

            when obj.type == "CharList" # && obj.value.length < 60
#                @write_value @html_value(obj)
                 @format_structure(obj)
                
            when obj.value.length < 60
                @write_value @html_value(obj)
            else
                @format_structure(obj)

    format_structure: (obj) ->
        nodes = [ @obj_to_tree(obj) ]
        tree = $("<div class='object-tree'></div>")
        tree.tree
            data:       nodes
            autoEscape: false
            autoOpen:   false
            selectable: false

        tree.bind "tree.open", @set_key_widths
        @write(tree)
        


    obj_to_tree: (obj) ->
        node = switch obj.class
                   when "container"
                       label:    @container_label(obj)
                       id:       @next_id()
                       children: (@obj_to_tree(child) for child in obj.children)
                       
                   when "pair"
                       if obj.right.value.length > 40 && obj.right.class == "container"
                           right_label = @container_label(obj.right)
                           label:    @pair_label(@html_value(obj.left), right_label)
                           id:       @next_id()
                           children: (@obj_to_tree(child) for child in obj.right.children)
                       else
                           label:    @pair_label(@html_value(obj.left), @html_value(obj.right))
                           id:       @next_id()
                           
                   when "leaf"
                       label: @html_value(obj)
                       id:    @next_id()
                       
                   else
                       console.log("Unknown value class: #{obj.class}")
                       console.dir(obj)

    html_value: (obj) ->
        "<span title='#{obj.type}'>#{@e(obj.value)}</span>"

    # Go through the tree looking for keyword lists. For each, look at the keys in
    # the children, setting the width of each to something consistent.

    set_key_widths: (event) =>
        console.dir event
        tree = $(event.node.element)
        console.log("looking at tree #{tree[0].innerText}")
        @set_key_width($(kw_list)) for kw_list in tree.find("span.KW_list")

    set_key_width: (kw_list) ->
        console.log("Keyword list #{kw_list[0].title}")
        child_tree = kw_list.parent().parent().next("ul")
        keys = child_tree.find("span.pair-left")
        console.dir(keys)
        widths = ($(key).width() for key in keys)
        max = Math.max.apply(Math, widths)
        if max > 0
            console.log("Max = #{max}")
            @add_leader($(key), max) for key in keys 

    add_leader: (key, width) ->
        holder = $(key).parent("div.pair-left-wrapper")
        holder.width width
        
    e: Eval.escape

    container_label: (obj) ->
        [value,size] = if obj.type == "CharList"
                           [@e(obj.value), "#{obj.children.length} chars"]
                       else
                           [obj.type, "#{obj.children.length} entries"]

            
        klass = obj.type.replace(/\s/, "_")
        "<span class='#{klass}' title='#{obj.type}'>#{value} (#{size})</class>"        

    pair_label: (left, right) ->
      "<div class='pair-left-wrapper'><span class='pair-left'>#{left}</span></div> " +
      "<span class='pair-right'>#{right}</span>"
          
    value: (obj) ->
        "<div class=\"value\">#{obj}</div>"

    write: (text) ->
        @op.append text

    write_value: (val) ->
        @write(@value(val))

    next_id: ->
        @id += 1
        "vt#{@id}"
