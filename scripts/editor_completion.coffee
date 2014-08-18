# Provide completion inside the Ace editor
# 
class @EditorCompletion

    constructor: (@rest, ace_language_tools) ->
        util = ace.require("ace/autocomplete/util")
        @oldPrefixFinder = util.retrievePrecedingIdentifier
        util.retrievePrecedingIdentifier = @retrievePrecedingIdentifier
        ace_language_tools.addCompleter(@)
        

    identifierRegexps: [
        /:[a-zA-Z0-9_]+(\.[a-zA-Z0-9_]+)+(!\?)?/,
        /[A-Z][a-zA-Z0-9_]*(\.[a-zA-Z0-9_]+)*(!\?)?/,
        /[a-zA-Z0-9_]+(!\?)?/
    ]

    retrievePrecedingIdentifier: (text, pos, regexp) =>
        console.log("preceding '#{text}', #{pos}, #{regexp}")
        text = text.substr(0, pos) unless pos == text.length
        if match = Util.find_something_to_complete(text)
            console.log "Finds #{match}"
            match
        else
            console.log "Finds nothing"
            @oldPrefixFinder(text, pos, regexp)
        
    getCompletions: (editor, session, pos, prefix, callback) =>
        result = []
        console.log("complete '#{pos}' '#{prefix}'")
        console.dir pos
#        match = Util.beginning_of_line_to_point(session, pos)
        @rest.get("autocomplete",
                  term: prefix,
                  (args) =>
                      console.dir args
                      results = @suggestions(args)
                      callback(null, results)
                  (args) =>
                      callback(true,  []))

    suggestions: (results) ->
        (@suggest(results.given.length, suggestion) for suggestion in results.suggest)
        
    suggest: (prefix_length, suggestion) ->
        value   = suggestion.name
        caption = value
        meta    = suggestion.kind

        if suggestion.type
            meta = "#{suggestion.type} #{suggestion.kind}"

        caption: caption
        value:   value
        score:   99
        meta:    meta
        

