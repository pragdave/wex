class @RestDriver

    constructor: (version) ->
        @api = "api/#{version}"

    get: (path, params, onDone, onFail) ->
        $.getJSON("#{@api}/#{path}", params)
        .done(onDone)
        .fail((jqxhr, text, error) ->
            onFail("#{text}: #{error}"))
