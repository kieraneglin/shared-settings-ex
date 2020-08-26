defmodule SharedSettings.Application do
  use Application

  alias SharedSettings.Cache.EtsStore

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: SharedSettings.Supervisor]
    children = [EtsStore.worker_spec()]

    Supervisor.start_link(children, opts)
  end
end
