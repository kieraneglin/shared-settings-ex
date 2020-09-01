defmodule SharedSettings do
  @moduledoc ~S"""
  SharedSettings is a library for fetching and updating settings at runtime.

  The goal of this is to provide a simple, language-agnostic storage interface
  as well as an accompanying Ruby gem (TODO) and UI (TODO).  This is not intended
  to be a fully-fledged feature flagging library (see FunWithFlags if you need that).
  Instead, this is geared toward updating settings represented by a string, integer, etc.,
  for the purpose of easing runtime tweaking of knobs.
  """

  alias SharedSettings.Config
  alias SharedSettings.Setting

  @cache Config.cache_adapter()
  @store Config.storage_adapter()

  @type setting_name :: atom() | String.t()
  @type setting_type :: atom() | String.t()

  @doc ~S"""
  Creates or updates a setting.

  Settings are unique by name and creating a second setting with the same name will overwrite the original.

  ## Arguments

  * `name` - An atom or string representing the name of the setting. Used for fetching/deleting
  * `type` - An atom or string of either `string`, `number`, `boolean`, or `range` that specifies the expected value
  * `value` - Any data with the type specified by `type`

  ## Returns

  If a setting is successfully stored, a tuple of `:ok` and the setting name as a string is returned.

  If a `value` is specified that doesn't match the `type`, a tuple of `{:error, :incompatible_type}` is returned.

  Any other failures (say, from the storage adaptor) will be returned as-is.
  Failures to write to cache will not be returned as an error so long as writing to storage succeeds.
  """
  @spec put(setting_name(), setting_type(), any()) :: {:ok, String.t()} | {:error, any()}
  def put(name, type, value) when is_atom(name) do
    setting_result =
      name
      |> Atom.to_string()
      |> Setting.build_setting(type, value)

    do_put(setting_result)
  end

  def put(name, type, value) when is_binary(name) do
    setting_result =
      name
      |> Setting.build_setting(type, value)

    do_put(setting_result)
  end

  defp do_put(setting_result) do
    case setting_result do
      {:ok, setting} ->
        @cache.put(setting)
        @store.put(setting)

      error ->
        error
    end
  end

  @doc ~S"""
  Fetches a setting by name.

  Fetches from cache first and falls back to storage if a setting isn't found/is expired.

  ## Arguments

  * `name` - An atom or string representing the name of the setting to fetch

  ## Returns

  If a setting is found, returns a tuple of `:ok` and the stored value

  If a setting is not found, returns `{:error, :not_found}`

  If there is an error with the storage adaptor that error is passed straight though as `{:error, any()}`
  """
  @spec get(setting_name()) :: {:ok, any()} | {:error, any()}
  def get(name) when is_atom(name) do
    stringified_name = Atom.to_string(name)

    do_get(stringified_name)
  end

  def get(name) when is_binary(name) do
    do_get(name)
  end

  defp do_get(stringified_name) do
    case @cache.get(stringified_name) do
      {:ok, setting} -> Setting.restore_value(setting)
      {:error, :miss, _} -> fetch_from_persistence(stringified_name)
    end
  end

  @doc ~S"""
  Fetches all stored settings.

  This method differs from others in the fact that:
  1) The cache isn't hit, only the source of truth (ie: the store)
  2) The raw `Setting.t()` is returned instead of the final re-hydrated value

  Both of these changes come from the fact that this is meant to feed the UI.
  The reason it's exposed on the main module is that there's a secondary personal usecase
  for setting presence validation on app boot.

  Since this is hitting the store directly thought should be put into if/how frequently this is called

  ## Returns

  If successful (even if no settings are found), returns `{:ok, [Setting.t()]}`

  If there is an error with the storage adaptor that error is passed straight though as `{:error, any()}`
  """
  @spec get_all() :: {:ok, [Setting.t()]} | {:error, any()}
  def get_all do
    @store.get_all()
  end

  @doc ~S"""
  Deletes a setting by name from cache and storage.

  ## Arguments

  * `name` - An atom representing the name of the setting to delete

  ## Returns

  If the setting was deleted `:ok` is returned.

  This method returns `:ok` if the setting wasn't found so it's safe to match on `:ok`
  """
  @spec delete(setting_name()) :: :ok
  def delete(name) when is_atom(name) do
    stringified_name = Atom.to_string(name)

    do_delete(stringified_name)
  end

  def delete(name) when is_binary(name) do
    do_delete(name)
  end

  defp do_delete(stringified_name) do
    @cache.delete(stringified_name)
    @store.delete(stringified_name)
  end

  @doc ~S"""
  Checks whether a given setting exists

  ## Arguments

  * `name` - An atom or string representing the name of the setting to check

  ## Returns

  Returns a boolean based on if the setting was found.

  This uses the same logic as `get` so cache is hit first
  """
  @spec exists?(setting_name()) :: boolean()
  def exists?(name) when is_atom(name) or is_binary(name) do
    case get(name) do
      {:ok, _} -> true
      _ -> false
    end
  end

  defp fetch_from_persistence(name) do
    case @store.get(name) do
      {:ok, setting} -> Setting.restore_value(setting)
      error -> error
    end
  end
end
