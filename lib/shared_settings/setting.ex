defmodule SharedSettings.Setting do
  @moduledoc false

  alias __MODULE__

  @enforce_keys [:name, :type, :value]
  defstruct [:name, :type, :value]

  @type t :: %SharedSettings.Setting{name: String.t(), type: String.t(), value: String.t()}

  def build_setting(name, value) when is_binary(value) do
    {:ok, %Setting{name: name, type: "string", value: value}}
  end

  def build_setting(name, value) when is_integer(value) or is_float(value) do
    {:ok, %Setting{name: name, type: "number", value: to_string(value)}}
  end

  def build_setting(name, value) when is_boolean(value) do
    stringified_value = if value, do: "1", else: "0"

    {:ok, %Setting{name: name, type: "boolean", value: stringified_value}}
  end

  def build_setting(name, value = %Range{}) do
    first..last = value
    stringified_value = "#{first},#{last}"

    {:ok, %Setting{name: name, type: "range", value: stringified_value}}
  end

  def build_setting(_name, _value) do
    {:error, :unsupported_type}
  end

  def restore_value(%Setting{type: "string", value: value}) do
    {:ok, value}
  end

  def restore_value(%Setting{type: "number", value: value}) do
    if String.contains?(value, ".") do
      {:ok, String.to_float(value)}
    else
      {:ok, String.to_integer(value)}
    end
  end

  def restore_value(%Setting{type: "boolean", value: value}) do
    case value do
      "1" -> {:ok, true}
      "0" -> {:ok, false}
    end
  end

  def restore_value(%Setting{type: "range", value: value}) do
    [lower, upper] =
      value
      |> String.split(",")
      |> Enum.map(&String.to_integer/1)

    {:ok, lower..upper}
  end
end
