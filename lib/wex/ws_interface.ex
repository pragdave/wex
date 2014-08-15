defmodule Wex.WSInterface do
  require Logger

  def child_spec do
    routes = :cowboy_router.compile([
        # {URIHost, list({URIPath, Handler, Opts})}
        {:_, [
          {'/ws',                   Wex.Web.WebSocket,          nil},
          {'/api/v1/autocomplete',  Wex.Web.Rest.Autocomplete,  nil},
          {'/api/v1/get_help',      Wex.Web.Rest.GetHelp,       nil},
          {'/api/v1/dirlist',       Wex.Web.Rest.Dirlist,       nil},

          {'/api/v1/file/load',     Wex.Web.Rest.LoadFile,      nil},

          {'/[...]', :cowboy_static, {:priv_dir, :wex, ""}},
        ]},
    ])

    :ranch.child_spec(Wex.WSInterface, 5, :ranch_tcp, [port: 8080], :cowboy_protocol, [env: [ dispatch: routes]])
  end

end
