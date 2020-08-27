defmodule SharedSettings.Config do
  def cache_ttl do
    Application.fetch_env!(:shared_settings, :cache_ttl)
  end

  def cache_adapter do
    Application.fetch_env!(:shared_settings, :cache_adapter)
  end

  def storage_adapter do
    Application.fetch_env!(:shared_settings, :storage_adapter)
  end
end
