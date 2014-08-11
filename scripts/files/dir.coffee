class @Files.Dir

    constructor: (@ws, @rest) ->
        @tree = []

    get_listing: (path) ->
      @rest.get("dirlist", dir: path, @get_listing_done, @get_listing_failed)

    get_listing_done: (@tree) =>
        WexEvent.trigger(WexEvent.dirlist_updated)

    get_listing_failed: () =>
        alert "Failed to get directory listing"
        
    
        
