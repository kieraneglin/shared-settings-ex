defmodule SharedSettings.Utilities.Timestamp do
  alias __MODULE__

  def now do
    DateTime.utc_now() |> DateTime.to_unix(:second)
  end

  def expired?(timestamp, ttl) do
    (timestamp + ttl) < Timestamp.now()
  end
end
