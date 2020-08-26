defmodule SharedSettings.Setting do
  @moduledoc """
  Provides a struct/type for the settings that go in and out of storage.

  The methods here aren't intended to be used on their own.
  SharedSettings should be the module you interface with
  """

  alias __MODULE__

  @enforce_keys [:name, :type, :value]
  defstruct [:name, :type, :value]

  @type t :: %SharedSettings.Setting{name: String.t(), type: String.t(), value: String.t()}

  # I'm using conditionals within the block instead of guards since there may be
  # other reasons the guards don't match that don't strictly imply that the
  # wrong type/value combo was passed.
  def build_setting(name, :string, value) do
    if is_binary(value) do
      {:ok, %Setting{name: name, type: "string", value: value}}
    else
      {:error, :incompatible_type}
    end
  end

  def build_setting(name, :number, value) do
    if is_integer(value) || is_float(value) do
      stringified_value = to_string(value)

      {:ok, %Setting{name: name, type: "number", value: stringified_value}}
    else
      {:error, :incompatible_type}
    end
  end

  def build_setting(name, :boolean, value) do
    if is_boolean(value) do
      stringified_value = if value, do: "1", else: "0"

      {:ok, %Setting{name: name, type: "boolean", value: stringified_value}}
    else
      {:error, :incompatible_type}
    end
  end

  def build_setting(name, :range, value) do
    if is_range(value) do
      first..last = value
      stringified_value = "#{first},#{last}"

      {:ok, %Setting{name: name, type: "range", value: stringified_value}}
    else
      {:error, :incompatible_type}
    end
  end

  defp is_range(%Range{}), do: true
  defp is_range(_), do: false
end
