defmodule SharedSettings.Utilities.Encryption do
  @moduledoc false

  @encryption_key_size 32

  def generate_aes_key(size \\ @encryption_key_size) do
    :crypto.strong_rand_bytes(size)
  end
end
