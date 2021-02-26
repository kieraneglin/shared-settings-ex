defmodule SharedSettings.Utilities.Encryption do
  @moduledoc false

  @aes_block_size 16
  @init_vector_size 16
  @encryption_key_size 32

  def generate_aes_key(size \\ @encryption_key_size) do
    :crypto.strong_rand_bytes(size)
  end

  def encrypt(key, clear_text) do
    init_vec = generate_aes_key(@init_vector_size)
    payload = pad(clear_text, @aes_block_size)

    try do
      cipher_text = :crypto.crypto_one_time(:aes_256_cbc, key, init_vec, payload, true)

      {:ok, {init_vec, cipher_text}}
    catch
      :error, {_, _, msg} ->
        {:error, format_erlang_error(msg)}
    end
  end

  def decrypt(key, init_vec, cipher_text) do
    try do
      plain_text = :crypto.crypto_one_time(:aes_256_cbc, key, init_vec, cipher_text, false)

      {:ok, unpad(plain_text)}
    catch
      :error, {_, _, msg} ->
        {:error, format_erlang_error(msg)}
    end
  end

  defp pad(data, block_size) do
    to_add = block_size - rem(byte_size(data), block_size)

    data <> to_string(:string.chars(to_add, to_add))
  end

  defp unpad(data) do
    to_remove = :binary.last(data)

    :binary.part(data, 0, byte_size(data) - to_remove)
  end

  defp format_erlang_error(error_charlist) do
    error_charlist
    |> List.to_string()
    |> String.trim()
    |> String.downcase()
    |> String.replace(" ", "_")
    |> String.to_atom()
  end
end
