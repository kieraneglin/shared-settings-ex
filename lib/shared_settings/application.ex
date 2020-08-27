defmodule SharedSettings.Application do
  @moduledoc false

  use Application

  alias SharedSettings.Cache.EtsStore
  alias SharedSettings.Persistence.Redis

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: SharedSettings.Supervisor]

    children = [
      Redis.worker_spec(),
      EtsStore.worker_spec()
    ]

    Supervisor.start_link(children, opts)
  end
end
