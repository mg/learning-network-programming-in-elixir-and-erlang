defmodule Chat.IntegrationTest do
  use ExUnit.Case, async: true

  import Chat.Protocol
  alias Chat.Message.{Register, Broadcast}

  test "server closes connection if client send register message twice" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 4000, [:binary])

    encoded_message = encode_message(%Register{username: "Alice"})

    # Send first register message
    :ok = :gen_tcp.send(socket, encoded_message)

    log =
      ExUnit.CaptureLog.capture_log(fn ->
        :ok = :gen_tcp.send(socket, encoded_message)
        assert_receive {:tcp_closed, ^socket}, 500
      end)

    assert log =~ "Protocol error: duplicate registration"
  end

  test "broadcasting messages" do
    client_jd = connect_user("jd")
    client_amy = connect_user("amy")
    client_bern = connect_user("bern")

    Process.sleep(100)

    broadcast_message = %Broadcast{from_username: "", contents: "hi"}
    encoded_message = encode_message(broadcast_message)
    :ok = :gen_tcp.send(client_amy, encoded_message)

    refute_receive {:tcp, ^client_amy, _data}

    assert_receive {:tcp, ^client_jd, data}, 500
    assert {:ok, msg, ""} = decode_message(data)
    assert msg == %Broadcast{from_username: "amy", contents: "hi"}

    assert_receive {:tcp, ^client_bern, data}, 500
    assert {:ok, msg, ""} = decode_message(data)
    assert msg == %Broadcast{from_username: "amy", contents: "hi"}
  end

  defp connect_user(username) do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 4000, [:binary])
    encoded_message = encode_message(%Register{username: username})
    :ok = :gen_tcp.send(socket, encoded_message)
    socket
  end
end
