defmodule Wex.Web.Rest.Restful do
  defmacro __using__(_) do
    quote location: :keep do

      require Logger


      def init(_type, _req, _opts) do
        Logger.metadata in: unquote(Atom.to_string(__MODULE__))
        Logger.info "starting"
        { :upgrade, :protocol, :cowboy_rest }
      end

      def terminate(_reason, _req, _state) do
        Logger.info "terminating"
        :ok
      end

      def content_types_provided(req, state) do
	      { [ {"application/json", :handler} ], 
          req, 
          state}
      end

      defoverridable [init: 3, terminate: 3]

      import Wex.Web.Rest.Restful, only: [ with_param: 2 ]

    end
  end


  @doc """
  Create an method named `handle` which is called back
  by the `content_types_provided` hook. The macro is
  passed the name of a request parameter, which we assign to a 
  local variable of the same name before embedding the passed block.
  The result of executing that block is encoded as JSON and
  becomes the result of the request.

  ## Example

        with_param :dir, do: Wex.FileManager.dirlist(dir)

  becomes

        def handler(req, state) do
          {[{"dir", dir}], req} = :cowboy_req.qs_vals(req)
          result = Wex.FileManager.dirlist(dir)
          {JSON.encode!(result), req, state}
        end   
  """
  defmacro with_param(param, block) when is_atom(param) do
    _with_param(param, block)
  end

  def _with_param(param, do: block) do
    quote  do
      def handler(req, state) do
        { [ { unquote(Atom.to_string(param)), 
              unquote(Macro.var(param, nil)) 
            } 
          ], 
          req 
        } = :cowboy_req.qs_vals(req)
        result = unquote(block)
        Logger.debug("#{unquote(param)} → #{inspect result}")
        { JSON.encode!(result), req, state }
      end
    end
  end

end
