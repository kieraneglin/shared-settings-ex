defmodule SharedSettings.Cache.EtsStore do
  @moduledoc false

  use GenServer

  alias SharedSettings.Config
  alias SharedSettings.Setting
  alias SharedSettings.Utilities.Timestamp

  @behaviour SharedSettings.Store

  @table_name :shared_settings_cache
  @table_options [
    :set,
    :protected,
    :named_table,
    {:read_concurrency, true}
  ]

  def worker_spec do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      restart: :permanent,
      type: :worker
    }
  end

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def get(setting_name) do
    case :ets.lookup(@table_name, setting_name) do
      [{^setting_name, {setting, timestamp, ttl}}] ->
        if Timestamp.expired?(timestamp, ttl) do
          {:error, :miss, :expired}
        else
          {:ok, setting}
        end

      _ ->
        {:error, :miss, :not_found}
    end
  end

  def put(setting = %Setting{}) do
    GenServer.call(__MODULE__, {:put, setting})
  end

  def delete(setting_name) do
    GenServer.call(__MODULE__, {:delete, setting_name})
  end

  def flush do
    GenServer.call(__MODULE__, :flush)
  end

  # GenServer callbacks

  def init(:ok) do
    :ets.new(@table_name, @table_options)

    {:ok, %{tab_name: @table_name, ttl: Config.cache_ttl()}}
  end

  def handle_call({:put, setting = %Setting{name: name}}, _from, state = %{ttl: ttl}) do
    :ets.insert(@table_name, {name, {setting, Timestamp.now(), ttl}})

    {:reply, {:ok, name}, state}
  end

  def handle_call({:delete, name}, _from, state) do
    :ets.delete(@table_name, name)

    {:reply, :ok, state}
  end

  def handle_call(:flush, _from, state) do
    {:reply, :ets.delete_all_objects(@table_name), state}
  end
end
