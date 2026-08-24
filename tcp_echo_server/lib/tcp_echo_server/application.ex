defmodule TCPEchoServer.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {TCPEchoServer.Acceptor, port: 4000}
    ]

    opts = [strategy: :one_for_one, name: TCPEchoServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
