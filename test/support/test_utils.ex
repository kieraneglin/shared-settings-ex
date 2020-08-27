defmodule SharedSettings.TestUtils do
  alias SharedSettings.Persistence.Redis
  alias SharedSettings.Utilities.Timestamp

  def unique_atom do
    String.to_atom(random_string())
  end

  def random_string do
    :crypto.strong_rand_bytes(7)
    |> Base.encode32(padding: false, case: :lower)
  end

  def flush_redis do
    Redix.command!(Redis, ["KEYS", "shared_settings:*"])
    |> delete_keys()
  end

  defp delete_keys([]), do: 0

  defp delete_keys(keys) do
    Redix.command!(Redis, ["DEL" | keys])
  end

  defmacro timetravel([by: offset], [do: body]) do
    quote do
      fake_now = Timestamp.now() + unquote(offset)

      with_mock(Timestamp, [
        now: fn() ->
          fake_now
        end,
        expired?: fn(timestamp, ttl) ->
          :meck.passthrough([timestamp, ttl])
        end
      ]) do
        unquote(body)
      end
    end
  end
end
