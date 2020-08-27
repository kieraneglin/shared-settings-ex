defmodule SharedSettings.Utilities.TimestampTest do
  use ExUnit.Case

  alias SharedSettings.Utilities.Timestamp

  describe "now/0" do
    test "returns integer timestamp" do
      assert is_integer(Timestamp.now())
    end
  end

  describe "expired?/2" do
    test "returns true when timestamp expired" do
      one_min_ago = Timestamp.now() - 60

      assert Timestamp.expired?(one_min_ago, 10)
      assert Timestamp.expired?(one_min_ago, 59)
    end

    test "returns false when timestamp is live" do
      one_min_ago = Timestamp.now() - 60

      refute Timestamp.expired?(one_min_ago, 61)
      refute Timestamp.expired?(one_min_ago, 3600)
    end
  end
end
