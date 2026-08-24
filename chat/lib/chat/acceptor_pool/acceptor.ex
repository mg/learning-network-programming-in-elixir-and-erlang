defmodule Chat.AcceptorPool.Acceptor do
  use GenServer

  alias Chat.AcceptorPool.ConnectionSupervisor

  require Logger

  @spec start_link(:gen_tcp.socket()) :: GenServer.on_start()
  def start_link(listen_socket) do
    GenServer.start_link(__MODULE__, listen_socket)
  end

  @impl true
  def init(listen_socket) do
    send(self(), :accept)
    {:ok, listen_socket}
  end

  @impl true
  def handle_info(:accept, listen_socket) do
    case :gen_tcp.accept(listen_socket) do
      {:ok, socket} ->
        {:ok, pid} = ConnectionSupervisor.start_connection(socket)
        :ok = :gen_tcp.controlling_process(socket, pid)
        send(self(), :accept)
        {:noreply, listen_socket}

      {:error, reason} ->
        Logger.error("Failed to accept connection: #{inspect(reason)}")
        {:stop, reason, listen_socket}
    end
  end
end
