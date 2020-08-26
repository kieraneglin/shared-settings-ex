defmodule SharedSettings.Persistence.RedisTest do
  use ExUnit.Case
  import SharedSettings.TestUtils

  alias SharedSettings.Setting
  alias SharedSettings.Persistence.Redis

  setup do
    flush_redis()
    name = random_string()
    setting = %Setting{name: name, type: "string", value: "test string"}

    {:ok, name: name, setting: setting}
  end

  describe "put/1" do
    test "stores a setting", %{name: name, setting: setting} do
      assert {:error, :not_found} = Redis.get(name)

      Redis.put(setting)

      assert {:ok, setting} = Redis.get(name)
    end

    test "overwrites existing setting", %{name: name, setting: setting} do
      Redis.put(setting)
      assert {:ok, ^setting} = Redis.get(name)

      new_setting = %Setting{name: name, type: "string", value: "new test string"}
      Redis.put(new_setting)

      assert {:ok, ^new_setting} = Redis.get(name)
    end

    test "returns {:ok, String.t()}", %{name: name, setting: setting} do
      assert {:ok, ^name} = Redis.put(setting)
    end
  end

  describe "get/1" do
    test "returns a setting if found", %{name: name, setting: setting} do
      Redis.put(setting)

      assert {:ok, ^setting} = Redis.get(name)
    end

    test "returns :not_found error if setting not found", %{name: name} do
      assert {:error, :not_found} = Redis.get(name)
    end
  end

  describe "delete/1" do
    test "deletes specified setting", %{name: name, setting: setting} do
      Redis.put(setting)
      assert {:ok, ^setting} = Redis.get(name)

      :ok = Redis.delete(name)

      assert {:error, :not_found} = Redis.get(name)
    end

    test "returns :ok if setting not found", %{name: name} do
      assert {:error, :not_found} = Redis.get(name)

      assert :ok = Redis.delete(name)
    end
  end
end
