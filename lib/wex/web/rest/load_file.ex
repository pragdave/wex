defmodule Wex.Web.Rest.LoadFile do

  use Wex.Web.Rest.Restful

  with_param :path  do
    case File.read(path) do
      {:ok, content} ->
        %{ status: "ok",    path: path, content: content }
      {:error, reason } ->
        %{ status: "error", path: path, message: :file.format_error(reason) }
    end
  end

end