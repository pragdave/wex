defmodule Wex.FileManager do

  require Logger

  def dirlist(path) do
    case file_or_dir(path, "") do
      list when is_map(list) -> list
      {:error, reason }      -> %{ error: reason }
    end
  end

  defp file_or_dir(top, relative_path) do
    full_path = "#{top}/#{relative_path}"
    case File.stat(full_path) do
      {:ok, %File.Stat{type: :directory, access: access}} when access != :none ->
        process_dir(full_path, relative_path)
      {:ok, %File.Stat{type: :regular, access: access}} when access != :none ->
        process_file(full_path, relative_path)
      { :ok, _ } ->
        nil
      { :error, reason } -> 
        { :error, reason }
    end
  end

  defp process_dir(full_path, relative_path) do
    { :ok, list } = File.ls(full_path)

    files = for file <- list, 
                entry = file_or_dir(full_path, file), 
                entry,  # is not nil...
                do: entry

    if length(files) == 0 do
      nil
    else
      %{ type:          "dir", 
         full_path:     full_path, 
         relative_path: relative_path,
         entries:       files 
       }
    end
  end

  defp process_file(full_path, relative_path) do
    %{ type: "file", full_path: full_path, relative_path: relative_path }
  end
    
end