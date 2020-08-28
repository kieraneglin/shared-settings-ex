import Config

config :shared_settings,
  cache_ttl: 300,
  cache_adapter: SharedSettings.Cache.EtsStore,
  storage_adapter: SharedSettings.Persistence.Redis
