defmodule Chat.ProtocolTest do
  use ExUnit.Case, async: true

  alias Chat.Message.{Broadcast, Register}

  describe "decode_message/1" do
    test "decodes a Register message" do
      binary = <<0x01, 4::16, "John", "rest">>
      assert {:ok, message, rest} = Chat.Protocol.decode_message(binary)

      assert message == %Register{username: "John"}
      assert rest == "rest"

      assert Chat.Protocol.decode_message(<<0x01, 0x00>>) == :incomplete
    end

    test "decodes a Broadcast message" do
      binary = <<0x02, 4::16, "John", 5::16, "Hello", "rest">>
      assert {:ok, message, rest} = Chat.Protocol.decode_message(binary)

      assert message == %Broadcast{from_username: "John", contents: "Hello"}
      assert rest == "rest"

      assert Chat.Protocol.decode_message(<<0x02, 0x00>>) == :incomplete
    end

    test "returns :incomplete for empty data" do
      assert Chat.Protocol.decode_message("") == :incomplete
    end

    test "returns :error for unknown message type" do
      assert Chat.Protocol.decode_message(<<0x03, "rest">>) == :error
    end
  end

  describe "encode_message/1" do
    test "encodes a Register message" do
      message = %Register{username: "John"}
      iodata = Chat.Protocol.encode_message(message)
      assert IO.iodata_to_binary(iodata) == <<0x01, 4::16, "John">>
    end

    test "encodes a Broadcast message" do
      message = %Broadcast{from_username: "John", contents: "Hello"}
      iodata = Chat.Protocol.encode_message(message)

      assert IO.iodata_to_binary(iodata) == <<0x02, 4::16, "John", 5::16, "Hello">>
    end
  end
end
