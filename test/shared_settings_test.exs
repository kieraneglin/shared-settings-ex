defmodule SharedSettingsTest do
  use ExUnit.Case, async: false
  import Mock
  import SharedSettings.TestUtils

  alias SharedSettings.Config
  alias SharedSettings.Setting
  alias SharedSettings.Cache.EtsStore
  alias SharedSettings.Persistence.Redis

  setup do
    flush_redis()
    EtsStore.flush()

    :ok
  end

  describe "put/3" do
    test "values are stored in cache" do
      name = unique_atom()

      {:ok, key} = SharedSettings.put(name, :string, "asdf")

      assert {:ok, %Setting{name: key, type: "string", value: "asdf"}} = EtsStore.get(key)
    end

    test "values are stored in persistence" do
      name = unique_atom()

      {:ok, key} = SharedSettings.put(name, :string, "asdf")

      assert {:ok, %Setting{name: key, type: "string", value: "asdf"}} = Redis.get(key)
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

    test "strings are supported for setting names and types" do
      {:ok, _} = SharedSettings.put(random_string(), "string", "asdf")
    end
  end

  describe "get/1" do
    test "values are retrieved" do
      name = unique_atom()

      SharedSettings.put(name, :string, "asdf")

      assert {:ok, "asdf"} = SharedSettings.get(name)
    end

    test "values are retrieved from cache first" do
      string_name = random_string()
      name = String.to_atom(string_name)
      cache_setting = %Setting{name: string_name, type: "string", value: "from cache"}
      store_setting = %Setting{name: string_name, type: "string", value: "from store"}

      EtsStore.put(cache_setting)
      Redis.put(store_setting)

      assert {:ok, "from cache"} = SharedSettings.get(name)
    end

    test "values are retrieved from storage if not found in cache" do
      string_name = random_string()
      name = String.to_atom(string_name)
      store_setting = %Setting{name: string_name, type: "string", value: "from store"}

      Redis.put(store_setting)

      assert {:ok, "from store"} = SharedSettings.get(name)
    end

    test "values are retrieved from storage if cache TTL expired" do
      string_name = random_string()
      name = String.to_atom(string_name)
      cache_setting = %Setting{name: string_name, type: "string", value: "from cache"}
      store_setting = %Setting{name: string_name, type: "string", value: "from store"}

      EtsStore.put(cache_setting)
      Redis.put(store_setting)

      timetravel by: Config.cache_ttl() + 1 do
        assert {:ok, "from store"} = SharedSettings.get(name)
      end
    end

    test "failure returns {:error, any()}" do
      name = unique_atom()

      assert {:error, :not_found} = SharedSettings.get(name)
    end
  end

  describe "get_all/0" do
    test "returns all settings" do
      # More tests exist in the Redis module tests.  This is more of a sanity check
      Redis.put(%Setting{name: random_string(), type: "string", value: random_string()})
      Redis.put(%Setting{name: random_string(), type: "string", value: random_string()})

      {:ok, settings} = Redis.get_all()

      assert length(settings) == 2
    end
  end

  describe "delete/1" do
    test "values are deleted from cache" do
      string_name = random_string()
      name = String.to_atom(string_name)
      EtsStore.put(%Setting{name: string_name, type: "string", value: "from cache"})

      SharedSettings.delete(name)

      assert {:error, :not_found} = SharedSettings.get(name)
    end

    test "values are deleted from storage" do
      string_name = random_string()
      name = String.to_atom(string_name)
      Redis.put(%Setting{name: string_name, type: "string", value: "from store"})

      SharedSettings.delete(name)

      assert {:error, :not_found} = SharedSettings.get(name)
    end
  end

  describe "exists?/1" do
    test "returns true when a setting exists" do
      name = unique_atom()

      SharedSettings.put(name, :string, "asdf")

      assert true == SharedSettings.exists?(name)
    end

    test "returns false when a setting does not exist" do
      name = unique_atom()

      assert false == SharedSettings.exists?(name)
    end
  end
end
