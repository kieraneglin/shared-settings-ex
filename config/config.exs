import Config

config :shared_settings,
  encryption_key: System.get_env("SHARED_SETTINGS_KEY"),
  cache_ttl: 300,
  cache_adapter: SharedSettings.Cache.EtsStore,
  storage_adapter: SharedSettings.Persistence.Redis
