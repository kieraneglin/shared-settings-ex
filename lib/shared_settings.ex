defmodule SharedSettings do
  @moduledoc """
  SharedSettings is a library for fetching and updating settings at runtime.

  The goal of this is to provide a simple, language-agnostic storage interface
  as well as an accompanying Ruby gem (TODO) and UI (TODO).  This is not intended
  to be a fully-fledged feature flagging library (see FunWithFlags if you need that).
  Instead, this is geared toward updating settings represented by a string, integer, etc.,
  for the purpose of easing runtime tweaking of knobs.
  """

  alias SharedSettings.Setting

  # TODO: swap this out for config once we have >1 storage adapter
  @store SharedSettings.Cache.EtsStore

  def put(name, type, value) when is_atom(name) and is_atom(type) do
    setting_result =
      name
      |> Atom.to_string()
      |> Setting.build_setting(type, value)

    case setting_result do
      {:ok, setting} -> @store.put(setting)
      error -> error
    end
  end

  def get(name) when is_atom(name) do
    stringified_name = Atom.to_string(name)

    case @store.get(stringified_name) do
      {:ok, setting} -> Setting.restore_value(setting)
      error -> error
    end
  end

  def exists?(name) when is_atom(name) do
    case get(name) do
      {:ok, _} -> true
      _ -> false
    end
  end
end
