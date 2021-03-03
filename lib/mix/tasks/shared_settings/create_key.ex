defmodule Mix.Tasks.SharedSettings.CreateKey do
  use Mix.Task

  alias SharedSettings.Utilities.Encryption

  @doc ~S"""
  Returns a key for encrypting settings
  """
  def run(_) do
    Encryption.generate_aes_key()
    |> Base.encode16()
    |> IO.puts()
  end
end
