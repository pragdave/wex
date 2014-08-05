defmodule Wex.Util.Text do
  @moduledoc """
  We implement a simple data structure to represent structured text
  """

  @doc "An error response"
  def error(msg), do: %{ stderr: msg }

  @doc "Regular text" 
  def text(msg), do:  %{ stdout: msg }

  @doc "Module or function help—a heading followed by some text"
  def help(body), do: %{ help: body }

  @doc "Help heading"
  def heading(text), do: %{ heading: text }
                   
  @doc "Things like types and specs"
  def subhead(text), do: %{ subhead: text }
                   
end