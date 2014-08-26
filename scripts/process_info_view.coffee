class @ProcessInfoView

    @source:   $("#process-info-template").html()
    @template: Handlebars.compile(@source)

    constructor: (launcher, @pid, @info, old_div) ->
        @div = $(ProcessInfoView.template(@info.v))
        tabs = @div.find(".pi-tabs").tabs
            collapsible: true
            
        name = @info.v.registered_name?.s
        title = if name
                  "Process #{name.replace(':', '')} (#{@pid})"
                else
                  "Process #{@pid}"
        
        @div.find("h1.title").text(title)
        if old_div
            active = old_div.find(".pi-tabs").tabs("option", "active")
            tabs.tabs("option", "active", active);            
            old_div.after(@div)
            old_div.remove()
        else
            $("#output").append(@div)

        @div.find("button.close").on("click",   => @div.remove())
        @div.find("button.refresh").on("click", => launcher.update(@pid, this))
        WexEvent.trigger(WexEvent.process_info_created, @div)


    update: (launcher, pid, data) =>
        ProcessTree.add_process_info(launcher, pid, data, @div)
        
        
String::remove_colon = () ->
    if this.startsWith(":")
        this.substr(1)
    else
        this
        
Handlebars.registerHelper 'v', (object) ->
    res = new ValueFormatter().format(object)
    if $.type(res) == "string"
        res
    else
        holder = $("<div></div>").uniqueId()
        id = holder.attr("id")
        setTimeout((=> $("#"+id).append(res)), 0)
        holder[0].outerHTML
        
        
Handlebars.registerHelper 'inspect', (object) ->
    object.s

Handlebars.registerHelper 'remove_colon', (str) ->
    str.remove_colon()

Handlebars.registerHelper 'format_mfa', (object) ->
    if object
        v = object.v
        if object.t == "Tuple" && v.length == 3
            "#{v[0].s}.#{v[1].s.remove_colon()}/#{v[2].s}"
        else
            object.s
    else
        "none"

