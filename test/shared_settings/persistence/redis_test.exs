defmodule SharedSettings.Persistence.RedisTest do
  use ExUnit.Case
  import SharedSettings.TestUtils

  alias SharedSettings.Setting
  alias SharedSettings.Persistence.Redis

  setup do
    flush_redis()
    name = random_string()
    {:ok, setting} = Setting.build(name, "test setting")
    {:ok, enc_setting} = Setting.build(name, "secret setting", encrypt: true)

    {:ok, name: name, setting: setting, enc_setting: enc_setting}
  end

  describe "put/1" do
    test "stores a setting", %{name: name, setting: setting} do
      assert {:error, :not_found} = Redis.get(name)

      Redis.put(setting)

      assert {:ok, ^setting} = Redis.get(name)
    end

    test "overwrites existing setting", %{name: name, setting: setting} do
      Redis.put(setting)
      assert {:ok, _} = Redis.get(name)

      new_setting = %Setting{
        name: name,
        type: "string",
        value: "new test string",
        encrypted: false
      }

      Redis.put(new_setting)

      assert {:ok, ^new_setting} = Redis.get(name)
    end

    test "returns {:ok, String.t()}", %{name: name, setting: setting} do
      assert {:ok, ^name} = Redis.put(setting)
    end

    test "stores an encrypted setting", %{name: name, enc_setting: enc_setting} do
      assert {:ok, ^name} = Redis.put(enc_setting)
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

    test "returns a decrypted setting", %{name: name, enc_setting: enc_setting} do
      Redis.put(enc_setting)

      assert {:ok, ^enc_setting} = Redis.get(name)
    end
  end

  describe "get_all/0" do
    test "returns all settings" do
      setting_one = %Setting{
        name: random_string(),
        type: "string",
        value: random_string(),
        encrypted: false
      }

      setting_two = %Setting{
        name: random_string(),
        type: "string",
        value: random_string(),
        encrypted: false
      }

      setting_three = %Setting{
        name: random_string(),
        type: "string",
        value: random_string(),
        encrypted: true
      }

      Redis.put(setting_one)
      Redis.put(setting_two)
      Redis.put(setting_three)

      {:ok, settings} = Redis.get_all()

      assert length(settings) == 3
      assert Enum.find(settings, fn setting -> setting.name == setting_one.name end)
      assert Enum.find(settings, fn setting -> setting.name == setting_two.name end)
      assert Enum.find(settings, fn setting -> setting.name == setting_three.name end)
    end

    test "returns all settings for larger numbers of keys" do
      Enum.each(0..24, fn _ ->
        Redis.put(%Setting{name: random_string(), type: "string", value: random_string()})
      end)

      {:ok, settings} = Redis.get_all()

      assert length(settings) == 25
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
