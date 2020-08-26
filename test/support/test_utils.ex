defmodule SharedSettings.TestUtils do
  @redis SharedSettings.Persistence.Redis

  def unique_atom do
    String.to_atom(random_string())
  end

  def random_string do
    :crypto.strong_rand_bytes(7)
    |> Base.encode32(padding: false, case: :lower)
  end

  def flush_redis do
    Redix.command!(@redis, ["KEYS", "shared_settings:*"])
    |> delete_keys()
  end

  defp delete_keys([]), do: 0

  defp delete_keys(keys) do
    Redix.command!(@redis, ["DEL" | keys])
  end
end
