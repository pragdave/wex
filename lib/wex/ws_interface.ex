defmodule Wex.WSInterface do
  require Logger

  def start_web_server(dispatcher_pid) do
    routes = :cowboy_router.compile([
        # {URIHost, list({URIPath, Handler, Opts})}
        {:_, [
          {'/ws',                   Wex.Web.WebSocket,          dispatcher_pid},
          {'/api/v1/autocomplete',  Wex.Web.Rest.Autocomplete,  nil},
          {'/api/v1/dirlist',       Wex.Web.Rest.Dirlist,       nil},

          {'/api/v1/file/load',     Wex.Web.Rest.LoadFile,      nil},

          {'/[...]', :cowboy_static, {:priv_dir, :wex, ""}},
        ]},
    ])
    
    # Name, NbAcceptors, TransOpts, ProtoOpts
    :cowboy.start_http(:my_http_listener, 100,
        [ port: 8080],
        [ env: [ dispatch: routes] ]
    )
    Logger.info "Cowboy started"
  end

end