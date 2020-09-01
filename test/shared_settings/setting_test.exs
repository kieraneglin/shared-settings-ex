defmodule SharedSettings.SettingTest do
  use ExUnit.Case
  import SharedSettings.TestUtils

  alias SharedSettings.Setting
  alias SharedSettings.Cache.EtsStore

  setup do
    flush_redis()
    EtsStore.flush()
    name = random_string()

    {:ok, name: name}
  end

  describe "build_setting/2" do
    test "string values are created as expected", %{name: name} do
      {:ok, setting} = Setting.build_setting(name, "test_string")

      assert setting == %Setting{name: name, type: "string", value: "test_string"}
    end

    test "number values are converted to strings", %{name: name} do
      {:ok, setting} = Setting.build_setting(name, 123)

      assert setting == %Setting{name: name, type: "number", value: "123"}
    end

    test "number type supports floats", %{name: name} do
      {:ok, setting} = Setting.build_setting(name, 12.3)

      assert setting == %Setting{name: name, type: "number", value: "12.3"}
    end

    test "number type supports negative numbers", %{name: name} do
      {:ok, setting} = Setting.build_setting(name, -123)

      assert setting == %Setting{name: name, type: "number", value: "-123"}
    end

    test "boolean values are converted to strings", %{name: name} do
      {:ok, true_setting} = Setting.build_setting(name, true)
      {:ok, false_setting} = Setting.build_setting(name, false)

      assert true_setting == %Setting{name: name, type: "boolean", value: "1"}
      assert false_setting == %Setting{name: name, type: "boolean", value: "0"}
    end

    test "range values are converted to strings", %{name: name} do
      {:ok, setting} = Setting.build_setting(name, 2..4)

      assert setting == %Setting{name: name, type: "range", value: "2,4"}
    end

    test "strings are supported for type names" do
      assert {:ok, _} = Setting.build_setting(random_string(), "test_string")
      assert {:ok, _} = Setting.build_setting(random_string(), 123)
      assert {:ok, _} = Setting.build_setting(random_string(), true)
      assert {:ok, _} = Setting.build_setting(random_string(), 1..5)
    end

    test "returns an error if type isn't supported" do
      assert {:error, :unsupported_type} = Setting.build_setting(random_string(), nil)
    end
  end

  describe "restore_value/1" do
    test "restores string values", %{name: name} do
      {:ok, setting} = Setting.build_setting(name, "asdf")

      assert {:ok, "asdf"} = Setting.restore_value(setting)
    end

    test "restores number values", %{name: name} do
      {:ok, number} = Setting.build_setting(name, 123)
      {:ok, neg_number} = Setting.build_setting(name, -123)
      {:ok, float} = Setting.build_setting(name, 12.3)

      assert {:ok, 123} = Setting.restore_value(number)
      assert {:ok, -123} = Setting.restore_value(neg_number)
      assert {:ok, 12.3} = Setting.restore_value(float)
    end

    test "restores boolean values", %{name: name} do
      {:ok, true_setting} = Setting.build_setting(name, true)
      {:ok, false_setting} = Setting.build_setting(name, false)

      assert {:ok, true} = Setting.restore_value(true_setting)
      assert {:ok, false} = Setting.restore_value(false_setting)
    end

    test "restores range values", %{name: name} do
      {:ok, setting} = Setting.build_setting(name, 2..4)

      assert {:ok, 2..4} = Setting.restore_value(setting)
    end
  end
end
