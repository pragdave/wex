defmodule Wex.Web.Rest.Restful do
  defmacro __using__(_) do
    quote location: :keep do

      use Jazz
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
	      { {"application/json", :handler}, req, state}
      end

      defoverridable [init: 3, terminate: 3]

    end
  end

end