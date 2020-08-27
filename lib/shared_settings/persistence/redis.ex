if Code.ensure_loaded?(Redix) do
  defmodule SharedSettings.Persistence.Redis do
    alias SharedSettings.Setting

    @behaviour SharedSettings.Store

    # TODO: remove and put into config
    @conn __MODULE__
    @default_redis_config [
      name: @conn,
      sync_connect: false,
      host: "localhost",
      port: 6379,
      database: 0
    ]

    @prefix "shared_settings"

    def worker_spec do
      Redix.child_spec(@default_redis_config)
    end

    def get(setting_name) do
      hash_name = format_name(setting_name)

      case Redix.command(@conn, ["HGETALL", hash_name]) do
        {:ok, result} -> parse_fetch_result(result)
        error -> error
      end
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
  end
end
