defmodule SharedSettings.Cache do
  @moduledoc ~S"""
  A behaviour module for cache adapters

  See `SharedSettings.Store` for more
  """

  alias SharedSettings.Setting

  @doc """
  Retrieves a setting by name.
  """
  @callback get(name :: String.t()) :: {:ok, Setting.t()} | {:error, any()}

  @doc """
  Persists a setting
  """
  @callback put(setting :: Setting.t()) :: {:ok, String.t()} | {:error, any()}

  @doc """
  Deletes a setting, identified by name.
  """
  @callback delete(name :: String.t()) :: :ok | {:error, any()}
end
