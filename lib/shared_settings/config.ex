defmodule SharedSettings.Config do
  @default_redis_config [
    host: "localhost",
    port: 6379,
    database: 0
  ]

  def cache_ttl do
    Application.fetch_env!(:shared_settings, :cache_ttl)
  end

  def cache_adapter do
    Application.fetch_env!(:shared_settings, :cache_adapter)
  end

  def storage_adapter do
    Application.fetch_env!(:shared_settings, :storage_adapter)
  end

  def redis_config do
    case Application.get_env(:shared_settings, :redis, []) do
      uri when is_binary(uri) ->
        uri
      opts when is_list(opts) ->
        Keyword.merge(@default_redis_config, opts)
      {:system, var} when is_binary(var) ->
        System.get_env(var)
    end
  end
end
