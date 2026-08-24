defmodule TCPEchoServerTest do
  use ExUnit.Case
  doctest TCPEchoServer

  test "sends back the received data" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 4000, [:binary, active: false])
    assert :ok = :gen_tcp.send(socket, "Hello, world!\n")
    {:ok, response} = :gen_tcp.recv(socket, 0)
    assert response == "Hello, world!\n"
    :gen_tcp.close(socket)
  end

  test "handles fragmented data" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 4000, [:binary, active: false])
    assert :ok = :gen_tcp.send(socket, "Hello, ")
    assert :ok = :gen_tcp.send(socket, "world!\nand one more line\n")
    {:ok, response} = :gen_tcp.recv(socket, 0)
    assert response == "Hello, world!\nand one more line\n"
    :gen_tcp.close(socket)
  end

  test "handles multiple clients simultaneously" do
    tasks =
      for _ <- 1..5 do
        Task.async(fn ->
          {:ok, socket} = :gen_tcp.connect(~c"localhost", 4000, [:binary, active: false])
          assert :ok = :gen_tcp.send(socket, "Hello from client!\n")
          {:ok, response} = :gen_tcp.recv(socket, 0)
          assert response == "Hello from client!\n"
          :gen_tcp.close(socket)
        end)
      end

    Task.await_many(tasks)
  end
end
