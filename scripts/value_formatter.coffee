class @ValueFormatter

    constructor: (@op) ->
        @id = 1000
        
    format: (obj) ->
        switch
            when $.type(obj) == "string"
                @value(obj)

            when obj.type == "CharList" && obj.value.length < 60
                @value("chars: #{obj.value}")
                
            when obj.value.length < 60
                @value(obj.value)
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
        e = Eval.escape
        node = switch obj.class
                   when "container"
                       label:    @container_label(obj)
                       id:       @next_id()
                       children: (@obj_to_tree(child) for child in obj.children)
                       
                   when "pair"
                       if obj.right.value.length > 40 && obj.right.class == "container"
                           right_label = @container_label(obj.right)
                           label:    @pair_label(e(obj.left.value), right_label)
                           id:       @next_id()
                           children: (@obj_to_tree(child) for child in obj.right.children)
                       else
                           label:    @pair_label(e(obj.left.value), e(obj.right.value))
                           id:       @next_id()
                           
                   when "leaf"
                       label: obj.value
                       id:    @next_id()
                       
                   else
                       console.log("Unknown value class: #{obj.class}")
                       console.dir(obj)


    # Go through the tree looking for keyword lists. For each, look at the keys in
    # the children, setting the width of each to something consistent.

    set_key_widths: (event) =>
        console.dir event
        tree = $(event.target)
        @set_key_width($(kw_list)) for kw_list in tree.find("span.KW_list")

    set_key_width: (kw_list) ->
        child_tree = kw_list.parent().parent().next("ul")
        keys = child_tree.find("span.pair-left")
        widths = ($(key).width() for key in keys)
        max = Math.max.apply(Math, widths)
        @add_leader($(key), max) for key in keys

    add_leader: (key, width) ->
        holder = $("<div style='width: #{width}px' class='pair-left-wrapper'></div>")
        new_key = key.clone()
        holder.html(new_key)
        key.replaceWith(holder)
        
    e: Eval.escape

    container_label: (obj) ->
        klass = obj.type.replace(/\s/, "_")
        "<span class='#{klass}'>#{obj.type} (#{obj.children.length} entries)</class>"        

    pair_label: (left, right) ->
      "<span class='pair-left'>#{left}</span> " +
      "<span class='pair-right'>#{right}</span>"
          
    value: (obj) ->
        @write "<div class=\"value\">#{@e(obj)}</div>"

    write: (text) ->
        @op.append text

    next_id: ->
        @id += 1
        "vt#{@id}"
