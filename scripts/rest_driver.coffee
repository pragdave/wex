class @RestDriver

    constructor: (version) ->
        @api = "api/#{version}"

    get: (path, params, onDone, onFail, extra_data) ->
        $.getJSON("#{@api}/#{path}", params)
        .done((data) -> onDone(data, params, extra_data))
        .fail((jqxhr, text, error) ->
            onFail("#{text}: #{error}"))
