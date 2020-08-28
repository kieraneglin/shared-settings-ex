defmodule SharedSettings.Store do
  @moduledoc ~S"""
  A behaviour module for store adapters (cache or persistent)

  All data values are represented by strings (similar to Redis).
  This means that, regardless of what adaptor is being implemented,
  all adaptors must accept and return data in the format which we will outline.

  Storage adaptors are only responsible for storing the setting as-given and returning
  it in the expected format. Here is a list of formats and their string representation:

  number: "1234"
  string: "any string"
  boolean: "1" or "0"
  range: "low,high". eg: "1,5"
  """

  alias SharedSettings.Setting

  @doc """
  Retrieves a setting by name.
  """
  @callback get(name :: String.t()) :: {:ok, Setting.t()}

  @doc """
  Persists a setting
  """
  @callback put(setting :: Setting.t()) :: {:ok, String.t()} | {:error, any()}

  @doc """
  Deletes a setting, identified by name.
  """
  @callback delete(name :: String.t()) :: :ok | {:error, any()}
end
