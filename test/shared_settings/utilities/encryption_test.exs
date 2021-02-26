defmodule SharedSettings.Utilities.EncryptionTest do
  use ExUnit.Case

  alias SharedSettings.Utilities.Encryption

  describe "generate_aes_key" do
    test "Returns key as bitstring" do
      key = Encryption.generate_aes_key()

      assert Kernel.is_bitstring(key)
    end

    test "Returns a 32 byte (256 bit) key by default" do
      key = Encryption.generate_aes_key()

      assert byte_size(key) == 32
    end

    test "Key size can be manually specified" do
      key = Encryption.generate_aes_key(16)

      assert byte_size(key) == 16
    end
  end
end
