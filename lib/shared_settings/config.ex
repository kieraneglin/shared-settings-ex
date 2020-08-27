defmodule SharedSettings.Config do
  def cache_ttl do
    Application.fetch_env!(:shared_settings, :cache_ttl)
  end
end
