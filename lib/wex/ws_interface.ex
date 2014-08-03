defmodule Wex.WSInterface do
  require Logger

  def start_web_server(dispatcher_pid) do
    routes = :cowboy_router.compile([
        # {URIHost, list({URIPath, Handler, Opts})}
        {:_, [
          {'/ws',    Wex.WS.Handler, dispatcher_pid},
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