class @ProcessInfoView

    @source:   $("#process-info-template").html()
    @template: Handlebars.compile(@source)

    constructor: (@pid, @info) ->
        console.dir @info
        div = $(ProcessInfoView.template(@info.v))
        div.find(".pi-tabs").tabs()
        
        div.dialog
            hide: 300
            show:
                effect:   "slideDown"
                duration: 400
            title: "Process: #{@pid}"

String::remove_colon = () ->
    if this.startsWith(":")
        this.substr(1)
    else
        this
        
Handlebars.registerHelper 'inspect', (object) ->
    object.s

Handlebars.registerHelper 'remove_colon', (str) ->
    str.remove_colon()

Handlebars.registerHelper 'mfa', (object) ->
    if object
        v = object.v
        if object.t == "Tuple" && v.length == 3
            "#{v[0].s}.#{v[1].s.remove_colon()}/#{v[2].s}"
        else
            object.s
    else
        "none"

