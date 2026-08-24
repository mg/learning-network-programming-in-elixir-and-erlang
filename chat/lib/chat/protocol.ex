defmodule Chat.Protocol do
  alias Chat.Message.{Broadcast, Register}

  @type message() :: Broadcast.t() | Register.t()

  @spec decode_message(binary()) ::
          {:ok, message(), binary()} | :error | :incomplete
  def decode_message(<<0x01, rest::binary>>), do: decode_register(rest)
  def decode_message(<<0x02, rest::binary>>), do: decode_broadcast(rest)
  def decode_message(<<>>), do: :incomplete
  def decode_message(<<_::binary>>), do: :error

  defp decode_register(<<
         username_len::16,
         username::size(username_len)-binary,
         rest::binary
       >>) do
    {:ok, %Register{username: username}, rest}
  end

  defp decode_register(<<_::binary>>), do: :incomplete

  defp decode_broadcast(<<
         username_len::16,
         username::size(username_len)-binary,
         contents_len::16,
         contents::size(contents_len)-binary,
         rest::binary
       >>) do
    {:ok, %Broadcast{from_username: username, contents: contents}, rest}
  end

  defp decode_broadcast(<<_::binary>>), do: :incomplete

  @spec encode_message(message()) :: iodata()
  def encode_message(%Register{} = message) do
    [0x01, encode_string(message.username)]
  end

  def encode_message(%Broadcast{} = message) do
    [
      0x02,
      encode_string(message.from_username),
      encode_string(message.contents)
    ]
  end

  defp encode_string(string) do
    [<<byte_size(string)::16>>, string]
  end
end
