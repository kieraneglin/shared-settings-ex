defmodule SharedSettingsTest do
  use ExUnit.Case
  import SharedSettings.TestUtils

  describe "put/3" do
    test "values are stored" do
      name = unique_atom()

      SharedSettings.put(name, :string, "asdf")

      assert {:ok, "asdf"} = SharedSettings.get(name)
    end

    test "success returns {:ok, String.t()}" do
      string_name = random_string()
      name = String.to_atom(string_name)

      assert {:ok, ^string_name} = SharedSettings.put(name, :string, "asdf")
    end

    test "failure returns {:error, any()}" do
      name = unique_atom()

      assert {:error, :incompatible_type} = SharedSettings.put(name, :string, 123)
    end
  end

  describe "get/1" do
    test "values are retrieved" do
      name = unique_atom()

      SharedSettings.put(name, :string, "asdf")

      assert {:ok, "asdf"} = SharedSettings.get(name)
    end

    test "failure returns {:error, any()}" do
      name = unique_atom()

      assert {:error, :not_found} = SharedSettings.get(name)
    end
  end
end
