defmodule SharedSettings do
  @moduledoc """
  SharedSettings is a library for fetching and updating settings at runtime.

  The goal of this is to provide a simple, language-agnostic storage interface
  as well as an accompanying Ruby gem (TODO) and UI (TODO).  This is not intended
  to be a fully-fledged feature flagging library (see FunWithFlags if you need that).
  Instead, this is geared toward updating settings represented by a string, integer, etc.,
  for the purpose of easing runtime tweaking of knobs.
  """

  # alias SharedSettings.Setting

  # TODO: swap this out for config once we have >1 storage adapter
  # @store SharedSettings.Cache.EtsStore

  # def create(name, type, value) when is_atom(name) and is_atom(type) do

  # end
end
