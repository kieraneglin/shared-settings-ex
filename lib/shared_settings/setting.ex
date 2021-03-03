defmodule SharedSettings.Setting do
  @moduledoc false

  alias __MODULE__
  alias SharedSettings.Config
  alias SharedSettings.Utilities.Encryption

  @enforce_keys [:name, :type, :value]
  defstruct [:name, :type, :value, encrypted: false]

  @type t :: %Setting{
          name: String.t(),
          type: String.t(),
          value: String.t(),
          encrypted: boolean()
        }

  def build(name, value, opts \\ []) do
    encrypt = Keyword.get(opts, :encrypt, false)

    case {encrypt, do_build(name, value)} do
      {_, {:error, msg}} ->
        {:error, msg}

      {false, {:ok, setting}} ->
        {:ok, setting}

      {true, {:ok, setting}} ->
        {:ok, encrypt_setting(setting)}
    end
  end

  def restore(setting) do
    case setting do
      %Setting{encrypted: true} ->
        setting
        |> decrypt_setting()
        |> do_restore()

      _ ->
        do_restore(setting)
    end
  end

  defp do_build(name, value) when is_binary(value) do
    {:ok, %Setting{name: name, type: "string", value: value}}
  end

  defp do_build(name, value) when is_integer(value) or is_float(value) do
    {:ok, %Setting{name: name, type: "number", value: to_string(value)}}
  end

  defp do_build(name, value) when is_boolean(value) do
    stringified_value = if value, do: "1", else: "0"

    {:ok, %Setting{name: name, type: "boolean", value: stringified_value}}
  end

  defp do_build(name, value = %Range{}) do
    first..last = value
    stringified_value = "#{first},#{last}"

    {:ok, %Setting{name: name, type: "range", value: stringified_value}}
  end

  defp do_build(_name, _value) do
    {:error, :unsupported_type}
  end

  defp encrypt_setting(old_setting = %Setting{value: value}) do
    {:ok, {iv, cipher_text}} = Encryption.encrypt(Config.encryption_key(), value)
    encrypted_value = "#{Base.encode16(iv)}|#{Base.encode16(cipher_text)}"

    %Setting{old_setting | value: encrypted_value, encrypted: true}
  end

  defp decrypt_setting(old_setting = %Setting{value: value, encrypted: true}) do
    [iv, cipher_text] =
      value
      |> String.split("|")
      |> Enum.map(&String.trim/1)
      |> Enum.map(&Base.decode16!/1)

    {:ok, plaintext_value} = Encryption.decrypt(Config.encryption_key(), iv, cipher_text)

    %Setting{old_setting | value: plaintext_value, encrypted: false}
  end

  defp do_restore(%Setting{type: "string", value: value}) do
    {:ok, value}
  end

  defp do_restore(%Setting{type: "number", value: value}) do
    if String.contains?(value, ".") do
      {:ok, String.to_float(value)}
    else
      {:ok, String.to_integer(value)}
    end
  end

  defp do_restore(%Setting{type: "boolean", value: value}) do
    case value do
      "1" -> {:ok, true}
      "0" -> {:ok, false}
    end
  end

  defp do_restore(%Setting{type: "range", value: value}) do
    [lower, upper] =
      value
      |> String.split(",")
      |> Enum.map(&String.to_integer/1)

    {:ok, lower..upper}
  end
end
