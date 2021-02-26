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

  describe "build/2" do
    test "string values are created as expected", %{name: name} do
      {:ok, setting} = Setting.build(name, "test_string")

      assert setting == %Setting{name: name, type: "string", value: "test_string"}
    end

    test "number values are converted to strings", %{name: name} do
      {:ok, setting} = Setting.build(name, 123)

      assert setting == %Setting{name: name, type: "number", value: "123"}
    end

    test "number type supports floats", %{name: name} do
      {:ok, setting} = Setting.build(name, 12.3)

      assert setting == %Setting{name: name, type: "number", value: "12.3"}
    end

    test "number type supports negative numbers", %{name: name} do
      {:ok, setting} = Setting.build(name, -123)

      assert setting == %Setting{name: name, type: "number", value: "-123"}
    end

    test "boolean values are converted to strings", %{name: name} do
      {:ok, true_setting} = Setting.build(name, true)
      {:ok, false_setting} = Setting.build(name, false)

      assert true_setting == %Setting{name: name, type: "boolean", value: "1"}
      assert false_setting == %Setting{name: name, type: "boolean", value: "0"}
    end

    test "range values are converted to strings", %{name: name} do
      {:ok, setting} = Setting.build(name, 2..4)

      assert setting == %Setting{name: name, type: "range", value: "2,4"}
    end

    test "returns an error if type isn't supported" do
      assert {:error, :unsupported_type} = Setting.build(random_string(), nil)
    end

    test "can optionally encrypt all supported types" do
      {:ok, %Setting{encrypted: true, value: str_val}} =
        Setting.build(random_string(), "str", encrypt: true)

      {:ok, %Setting{encrypted: true, value: int_val}} =
        Setting.build(random_string(), 1, encrypt: true)

      {:ok, %Setting{encrypted: true, value: bool_val}} =
        Setting.build(random_string(), true, encrypt: true)

      {:ok, %Setting{encrypted: true, value: range_val}} =
        Setting.build(random_string(), 1..3, encrypt: true)

      # This isn't an ideal test, but at least it tests that the struct key is set, that the
      # output length is far greater than the input length, and that the iv/cipher separator exists.
      # The round-trip test when it comes to decryption will be much more valuable
      assert String.length(str_val) > 16 and String.contains?(str_val, "|")
      assert String.length(int_val) > 16 and String.contains?(int_val, "|")
      assert String.length(bool_val) > 16 and String.contains?(bool_val, "|")
      assert String.length(range_val) > 16 and String.contains?(range_val, "|")
    end
  end

  describe "restore/1" do
    test "restores string values", %{name: name} do
      {:ok, setting} = Setting.build(name, "asdf")

      assert {:ok, "asdf"} = Setting.restore(setting)
    end

    test "restores number values", %{name: name} do
      {:ok, number} = Setting.build(name, 123)
      {:ok, neg_number} = Setting.build(name, -123)
      {:ok, float} = Setting.build(name, 12.3)

      assert {:ok, 123} = Setting.restore(number)
      assert {:ok, -123} = Setting.restore(neg_number)
      assert {:ok, 12.3} = Setting.restore(float)
    end

    test "restores boolean values", %{name: name} do
      {:ok, true_setting} = Setting.build(name, true)
      {:ok, false_setting} = Setting.build(name, false)

      assert {:ok, true} = Setting.restore(true_setting)
      assert {:ok, false} = Setting.restore(false_setting)
    end

    test "restores range values", %{name: name} do
      {:ok, setting} = Setting.build(name, 2..4)

      assert {:ok, 2..4} = Setting.restore(setting)
    end

    test "decrypts settings if applicable" do
      {:ok, str_setting} = Setting.build(random_string(), "str", encrypt: true)
      {:ok, int_setting} = Setting.build(random_string(), 1, encrypt: true)
      {:ok, bool_setting} = Setting.build(random_string(), true, encrypt: true)
      {:ok, range_setting} = Setting.build(random_string(), 1..3, encrypt: true)

      assert {:ok, "str"} = Setting.restore(str_setting)
      assert {:ok, 1} = Setting.restore(int_setting)
      assert {:ok, true} = Setting.restore(bool_setting)
      assert {:ok, 1..3} = Setting.restore(range_setting)
    end
  end
end
