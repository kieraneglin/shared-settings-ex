defmodule SharedSettings.Setting do
  @moduledoc false

  alias __MODULE__

  @enforce_keys [:name, :type, :value]
  defstruct [:name, :type, :value]

  @type t :: %SharedSettings.Setting{name: String.t(), type: String.t(), value: String.t()}

  # I'm using conditionals within the block instead of guards since there may be
  # other reasons the guards don't match that don't strictly imply that the
  # wrong type/value combo was passed.
  def build_setting(name, type, value) when type in ["string", :string] do
    if is_binary(value) do
      {:ok, %Setting{name: name, type: "string", value: value}}
    else
      {:error, :incompatible_type}
    end
  end

  def build_setting(name, type, value) when type in ["number", :number] do
    if is_integer(value) || is_float(value) do
      stringified_value = to_string(value)

      {:ok, %Setting{name: name, type: "number", value: stringified_value}}
    else
      {:error, :incompatible_type}
    end
  end

  def build_setting(name, type, value) when type in ["boolean", :boolean] do
    if is_boolean(value) do
      stringified_value = if value, do: "1", else: "0"

      {:ok, %Setting{name: name, type: "boolean", value: stringified_value}}
    else
      {:error, :incompatible_type}
    end
  end

  def build_setting(name, type, value) when type in ["range", :range] do
    if is_range(value) do
      first..last = value
      stringified_value = "#{first},#{last}"

      {:ok, %Setting{name: name, type: "range", value: stringified_value}}
    else
      {:error, :incompatible_type}
    end
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

  defp is_range(%Range{}), do: true
  defp is_range(_), do: false
end
