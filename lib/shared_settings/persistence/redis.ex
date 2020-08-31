if Code.ensure_loaded?(Redix) do
  defmodule SharedSettings.Persistence.Redis do
    @moduledoc false

    alias SharedSettings.Config
    alias SharedSettings.Setting

    @behaviour SharedSettings.Store

    @conn __MODULE__
    @conn_options [name: @conn, sync_connect: false]
    @prefix "shared_settings"

    def worker_spec do
      config =
        case Config.redis_config() do
          uri when is_binary(uri) ->
            {uri, @conn_options}

          opts when is_list(opts) ->
            Keyword.merge(opts, @conn_options)
        end

      Redix.child_spec(config)
    end

    def get(setting_name) do
      hash_name = format_name(setting_name)

      case Redix.command(@conn, ["HGETALL", hash_name]) do
        {:ok, result} -> parse_fetch_result(result)
        error -> error
      end
    end

    def get_all do
      {:ok, keys} = keys_by_prefix("#{@prefix}:*")

      settings =
        Enum.map(keys, fn @prefix <> ":" <> key ->
          {:ok, setting} = get(key)

          setting
        end)

      {:ok, settings}
    end

    def put(setting = %Setting{name: setting_name}) do
      hash_name = format_name(setting_name)
      serialized_data = serialize_setting(setting)

      case Redix.command(@conn, ["HSET" | [hash_name | serialized_data]]) do
        {:ok, _} -> {:ok, setting_name}
        error -> error
      end
    end

    def delete(setting_name) do
      hash_name = format_name(setting_name)

      case Redix.command(@conn, ["DEL", hash_name]) do
        {:ok, _} -> :ok
        error -> error
      end
    end

    defp parse_fetch_result(result) do
      case result do
        [] -> {:error, :not_found}
        _ -> {:ok, deserialize_setting(result)}
      end
    end

    defp format_name(setting_name) do
      "#{@prefix}:#{setting_name}"
    end

    defp serialize_setting(%Setting{name: name, type: type, value: value}) do
      ["name", name, "type", type, "value", value]
    end

    defp deserialize_setting([_n, name, _t, type, _v, value]) do
      %Setting{name: name, type: type, value: value}
    end

    defp keys_by_prefix(prefix) do
      case Redix.command(@conn, ["SCAN", "0", "MATCH", prefix]) do
        {:ok, response} -> get_keys_by_prefix(response, prefix)
        error -> error
      end
    end

    defp get_keys_by_prefix(["0", keys], _prefix) do
      {:ok, keys}
    end

    defp get_keys_by_prefix([cursor, keys], prefix) do
      case Redix.command(@conn, ["SCAN", cursor, "MATCH", prefix]) do
        {:ok, [new_cursor, new_keys]} ->
          get_keys_by_prefix([new_cursor, keys ++ new_keys], prefix)

        error ->
          error
      end
    end
  end
end
