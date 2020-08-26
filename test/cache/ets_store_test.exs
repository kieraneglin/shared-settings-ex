defmodule SharedSettings.Cache.EtsStoreTest do
  use ExUnit.Case
  import SharedSettings.TestUtils

  alias SharedSettings.Setting
  alias SharedSettings.Cache.EtsStore

  setup do
    EtsStore.flush()
    name = random_string()
    setting = %Setting{name: name, type: "string", value: "test string"}

    {:ok, name: name, setting: setting}
  end

  describe "put/1" do
    test "stores a setting", %{name: name, setting: setting} do
      assert {:error, :not_found} = EtsStore.get(name)

      EtsStore.put(setting)

      assert {:ok, ^setting} = EtsStore.get(name)
    end

    test "overwrites existing setting", %{name: name, setting: setting} do
      EtsStore.put(setting)
      assert {:ok, ^setting} = EtsStore.get(name)

      new_setting = %Setting{name: name, type: "string", value: "new test string"}
      EtsStore.put(new_setting)

      assert {:ok, ^new_setting} = EtsStore.get(name)
    end

    test "returns {:ok, %Setting{}}", %{setting: setting} do
      assert {:ok, ^setting} = EtsStore.put(setting)
    end
  end

  describe "get/1" do
    test "returns a setting if found", %{name: name, setting: setting} do
      EtsStore.put(setting)

      assert {:ok, ^setting} = EtsStore.get(name)
    end

    test "returns :not_found error if setting not found", %{name: name} do
      assert {:error, :not_found} = EtsStore.get(name)
    end
  end

  describe "delete/1" do
    test "deletes specified setting", %{name: name, setting: setting} do
      EtsStore.put(setting)
      assert {:ok, ^setting} = EtsStore.get(name)

      :ok = EtsStore.delete(name)

      assert {:error, :not_found} = EtsStore.get(name)
    end

    test "returns :ok if setting not found", %{name: name} do
      assert {:error, :not_found} = EtsStore.get(name)

      assert :ok = EtsStore.delete(name)
    end
  end
end
