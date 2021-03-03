defmodule SharedSettingsTest do
  use ExUnit.Case, async: false
  import Mock
  import SharedSettings.TestUtils

  alias SharedSettings.Config
  alias SharedSettings.Setting

  @cache Config.cache_adapter()
  @store Config.storage_adapter()

  setup do
    # Run before just in case there are any values left from other tests
    flush_redis()
    @cache.flush()

    # Get 'em twice to ensure we've fully cleaned up after tests have run
    on_exit(fn ->
      flush_redis()
      @cache.flush()
    end)

    :ok
  end

  describe "put/2" do
    test "values are stored in cache" do
      name = unique_atom()

      {:ok, key} = SharedSettings.put(name, "asdf")

      assert {:ok, %Setting{name: ^key, type: "string", value: "asdf"}} = @cache.get(key)
    end

    test "values are stored in persistence" do
      name = unique_atom()

      {:ok, key} = SharedSettings.put(name, "asdf")

      assert {:ok, %Setting{name: ^key, type: "string", value: "asdf"}} = @store.get(key)
    end

    test "success returns {:ok, String.t()}" do
      string_name = random_string()
      name = String.to_atom(string_name)

      assert {:ok, ^string_name} = SharedSettings.put(name, "asdf")
    end

    test "failure returns {:error, any()}" do
      name = unique_atom()

      assert {:error, :unsupported_type} = SharedSettings.put(name, nil)
    end

    test "strings are supported for setting names and types" do
      {:ok, string_name} = SharedSettings.put(random_string(), "asdf")

      assert {:ok, "asdf"} = SharedSettings.get(string_name)
    end

    test "encrypt flag stores values with encryption" do
      name = unique_atom()

      {:ok, key} = SharedSettings.put(name, "secret", encrypt: true)

      {:ok, %Setting{value: ets_val, encrypted: true}} = @cache.get(key)
      {:ok, %Setting{value: store_val, encrypted: true}} = @store.get(key)

      # As said in `setting_test.exs`, this isn't an ideal test but it has its merits.
      # It checks that the value is longer than expected and that the iv/cipher separator exists.
      # The round-trip encryption test will be more valuable
      assert ets_val == store_val
      assert String.length(ets_val) > 16 and String.contains?(ets_val, "|")
      assert String.length(store_val) > 16 and String.contains?(store_val, "|")
    end

    test "encryption blows up if no encryption key is specified" do
      old_key = Application.get_env(:shared_settings, :encryption_key)
      Application.put_env(:shared_settings, :encryption_key, nil)

      exception =
        assert_raise RuntimeError, fn ->
          SharedSettings.put(unique_atom(), "secret", encrypt: true)
        end

      assert exception.message == "Encryption key not provided"

      Application.put_env(:shared_settings, :encryption_key, old_key)
    end
  end

  describe "get/1" do
    test "values are retrieved" do
      name = unique_atom()

      SharedSettings.put(name, "asdf")

      assert {:ok, "asdf"} = SharedSettings.get(name)
    end

    test "values are retrieved from cache first" do
      string_name = random_string()
      name = String.to_atom(string_name)
      cache_setting = %Setting{name: string_name, type: "string", value: "from cache"}
      store_setting = %Setting{name: string_name, type: "string", value: "from store"}

      @cache.put(cache_setting)
      @store.put(store_setting)

      assert {:ok, "from cache"} = SharedSettings.get(name)
    end

    test "values are retrieved from storage if not found in cache" do
      string_name = random_string()
      name = String.to_atom(string_name)
      store_setting = %Setting{name: string_name, type: "string", value: "from store"}

      @store.put(store_setting)

      assert {:ok, "from store"} = SharedSettings.get(name)
    end

    test "values are retrieved from storage if cache TTL expired" do
      string_name = random_string()
      name = String.to_atom(string_name)
      cache_setting = %Setting{name: string_name, type: "string", value: "from cache"}
      store_setting = %Setting{name: string_name, type: "string", value: "from store"}

      @cache.put(cache_setting)
      @store.put(store_setting)

      timetravel by: Config.cache_ttl() + 1 do
        assert {:ok, "from store"} = SharedSettings.get(name)
      end
    end

    test "failure returns {:error, any()}" do
      name = unique_atom()

      assert {:error, :not_found} = SharedSettings.get(name)
    end

    test "string names are supported for fetching settings" do
      {:ok, string_name} = SharedSettings.put(unique_atom(), "asdf")

      assert {:ok, "asdf"} = SharedSettings.get(string_name)
    end

    test "encrypted settings are retrieved and decrypted" do
      name = unique_atom()
      value = 1234

      {:ok, key} = SharedSettings.put(name, value, encrypt: true)
      {:ok, %Setting{value: ets_val, encrypted: true}} = @cache.get(key)
      {:ok, %Setting{value: store_val, encrypted: true}} = @store.get(key)

      {:ok, fetched_val} = SharedSettings.get(name)

      assert ets_val != value
      assert store_val != value
      assert fetched_val == value
    end
  end

  describe "get_all/0" do
    test "returns settings in their raw form" do
      name = random_string()
      {:ok, _} = SharedSettings.put(name, "asdf")

      {:ok, [setting]} = SharedSettings.get_all()

      assert setting == %Setting{
               encrypted: false,
               name: name,
               type: "string",
               value: "asdf"
             }
    end

    test "decrypted values are returned with `encrypted` flag maintained" do
      name = random_string()
      {:ok, _} = SharedSettings.put(name, "asdf", encrypt: true)

      {:ok, [setting]} = SharedSettings.get_all()

      assert setting == %Setting{
               encrypted: true,
               name: name,
               type: "string",
               value: "asdf"
             }
    end
  end

  describe "delete/1" do
    test "values are deleted from cache" do
      string_name = random_string()
      name = String.to_atom(string_name)
      @cache.put(%Setting{name: string_name, type: "string", value: "from cache"})

      SharedSettings.delete(name)

      assert {:error, :not_found} = SharedSettings.get(name)
    end

    test "values are deleted from storage" do
      string_name = random_string()
      name = String.to_atom(string_name)
      @store.put(%Setting{name: string_name, type: "string", value: "from store"})

      SharedSettings.delete(name)

      assert {:error, :not_found} = SharedSettings.get(name)
    end

    test "string names are supported for deleting settings" do
      {:ok, string_name} = SharedSettings.put(unique_atom(), "asdf")

      :ok = SharedSettings.delete(string_name)

      assert {:error, :not_found} = SharedSettings.get(string_name)
    end
  end

  describe "exists?/1" do
    test "returns true when a setting exists" do
      name = unique_atom()

      SharedSettings.put(name, "asdf")

      assert true == SharedSettings.exists?(name)
    end

    test "returns false when a setting does not exist" do
      name = unique_atom()

      assert false == SharedSettings.exists?(name)
    end

    test "string names are supported" do
      name = random_string()

      SharedSettings.put(name, "asdf")

      assert true == SharedSettings.exists?(name)
    end
  end
end
