defmodule Wex.WS.Rest do

#  @behaviour :cowboy_http_handler
#  @behaviour :cowboy_rest_handler

  use Jazz

  require Logger


  # HTTP side

  def init(_type, _req, _opts) do
    Logger.info "rest init"
    { :upgrade, :protocol, :cowboy_rest }
  end

  def terminate(_reason, _req, _state), do: :ok


  # Rest side

  def content_types_provided(req, state) do
    Logger.info inspect(req)
	  {[
		  {"application/json", :autocomplete}
   	], 
    req, 
    state}
  end

  def autocomplete(req, state) do
    { a, _b } = :cowboy_req.qs_vals(req)
    Logger.info inspect(a)
    { [ {"term", term} ], req } = :cowboy_req.qs_vals(req)
    expand_param = term |> String.to_char_list |> Enum.reverse
    result = case IEx.Autocomplete.expand(expand_param) do
      { :no, _, _ } ->
        []
      { :yes, word, [] } when is_list(word) ->
        [ List.to_string(word) ]
      { :yes, [], words } when is_list(words) ->
        for word <- words, do: List.to_string(word)
    end
    { Jazz.encode!(result), req, state }
  end


end