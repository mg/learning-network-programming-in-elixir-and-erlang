defmodule TCPEchoServer.Acceptor do
  use GenServer

  require Logger

  def start_link(options) do
    GenServer.start_link(__MODULE__, options)
  end

  @impl true
  def init(options) do
    port = Keyword.fetch!(options, :port)
    ip = Keyword.get(options, :ip, {0, 0, 0, 0})

    listen_options = [
      :binary,
      # ip: ip,
      active: true,
      exit_on_close: false,
      reuseaddr: true,
      backlog: 25
    ]

    case :gen_tcp.listen(port, listen_options) do
      {:ok, listen_socket} ->
        Logger.info("Started TCP echo server on #{:inet.ntoa(ip)}:#{port}")
        send(self(), :accept)
        {:ok, listen_socket}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_info(:accept, listen_socket) do
    case :gen_tcp.accept(listen_socket, 2_000) do
      {:ok, socket} ->
        {:ok, pid} = TCPEchoServer.Connection.start_link(socket)
        :ok = :gen_tcp.controlling_process(socket, pid)
        send(self(), :accept)
        {:noreply, listen_socket}

      {:error, :timeout} ->
        send(self(), :accept)
        {:noreply, listen_socket}

      {:error, reason} ->
        {:stop, reason, listen_socket}
    end
  end
end
