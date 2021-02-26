defmodule SharedSettings.Utilities.EncryptionTest do
  use ExUnit.Case

  alias SharedSettings.Utilities.Encryption

  describe "generate_aes_key" do
    test "returns key as bitstring" do
      key = Encryption.generate_aes_key()

      assert Kernel.is_bitstring(key)
    end

    test "returns a 32 byte (256 bit) key by default" do
      key = Encryption.generate_aes_key()

      assert byte_size(key) == 32
    end

    test "key size can be manually specified" do
      key = Encryption.generate_aes_key(16)

      assert byte_size(key) == 16
    end
  end

  describe "encrypt" do
    test "returns IV and data successfully" do
      key = Encryption.generate_aes_key()

      {:ok, {iv, data}} = Encryption.encrypt(key, "supersecret")

      assert is_bitstring(iv)
      assert is_bitstring(data)
    end

    test "returns a errors in an Elixir-friendly format" do
      key = Encryption.generate_aes_key(12)

      assert {:error, :bad_key_size} = Encryption.encrypt(key, "supersecret")
    end
  end

  describe "decrypt" do
    test "decrypts data successfully, confirming roundtrip encryption" do
      key = Encryption.generate_aes_key()
      {:ok, {iv, enc_data}} = Encryption.encrypt(key, "supersecret")

      {:ok, plain_text} = Encryption.decrypt(key, iv, enc_data)

      assert plain_text == "supersecret"
    end

    test "returns a errors in an Elixir-friendly format" do
      bad_key = Encryption.generate_aes_key(12)
      good_key = Encryption.generate_aes_key(32)

      bad_iv = Encryption.generate_aes_key(12)
      good_iv = Encryption.generate_aes_key(16)

      assert {:error, :bad_key_size} = Encryption.decrypt(bad_key, good_iv, <<0>>)
      assert {:error, :bad_iv_size} = Encryption.decrypt(good_key, bad_iv, <<0>>)
    end
  end
end
