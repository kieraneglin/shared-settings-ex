defmodule SharedSettingsTest do
  use ExUnit.Case
  doctest SharedSettings

  test "greets the world" do
    assert SharedSettings.hello() == :world
  end
end
