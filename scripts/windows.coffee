class @Windows

    $(window).bind "keydown.f1", @one_pane

    @one_pane: ->
        alert("one")

$ ->
    $('#frame').split
        orientation: 'horizontal'
        limit: 100
        position: '75%'

    $('#editor-and-tree').split
        orientation: 'vertical'
        limit: 100
        position: '20%'

