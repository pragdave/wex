class @RestDriver

    constructor: (version) ->
        @api = "api/#{version}"

    get: (path, params, onDone, onFail) ->
        $.getJSON("#{@api}/#{path}", params)
        .done((data) -> onDone(data, params))
        .fail((jqxhr, text, error) ->
            onFail("#{text}: #{error}"))
