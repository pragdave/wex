defmodule Wex.Web.Rest.Dirlist do

  use Wex.Web.Rest.Restful

  with_param :dir, do: Wex.FileManager.dirlist(dir)

end