defmodule Chat.Connection do
  use GenServer, restart: :temporary

  alias Chat.Message.{Register, Broadcast}

  require Logger

  @spec start_link(:gen_tcp.socket()) :: GenServer.on_start()
  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  defstruct [:socket, :username, buffer: <<>>]

  @impl true
  def init(socket) do
    {:ok, %__MODULE__{socket: socket}}
  end

  @impl true
  def handle_info(message, state)

  def handle_info({:tcp, socket, data}, %__MODULE__{socket: socket} = state) do
    state = update_in(state.buffer, &(&1 <> data))
    :ok = :inet.setopts(socket, active: :once)
    handle_new_data(state)
  end

  def handle_info({:tcp_closed, _socket}, state) do
    {:stop, :normal, state}
  end

  def handle_info({:broadcast, %Broadcast{} = message}, state) do
    :ok = :gen_tcp.send(state.socket, Chat.Protocol.encode_message(message))
    {:noreply, state}
  end

  defp handle_new_data(%__MODULE__{buffer: buffer} = state) do
    case Chat.Protocol.decode_message(buffer) do
      {:ok, message, rest} ->
        state = put_in(state.buffer, rest)

        case handle_message(message, state) do
          {:ok, state} ->
            handle_new_data(state)

          :error ->
            {:stop, :normal, state}
        end

      :incomplete ->
        {:noreply, state}

      :error ->
        Logger.error("Protocol error: invalid message received")
        {:stop, :normal, state}
    end
  end

  defp handle_message(%Register{username: username}, %__MODULE__{username: nil} = state) do
    {:ok, _} = Registry.register(Chat.BroadcastRegistry, :broadcast, :no_value)
    {:ok, _} = Registry.register(Chat.UsernameRegistry, username, :no_value)
    state = put_in(state.username, username)
    {:ok, state}
  end

  defp handle_message(%Register{}, _state) do
    Logger.error("Protocol error: duplicate registration")
    :error
  end

  defp handle_message(%Broadcast{}, %__MODULE__{username: nil}) do
    Logger.error("Protocol error: Broadcast message received before registration")
    :error
  end

  defp handle_message(%Broadcast{} = message, state) do
    sender = self()
    message = %Broadcast{message | from_username: state.username}

    Registry.dispatch(Chat.BroadcastRegistry, :broadcast, fn entries ->
      Enum.each(entries, fn {pid, _} ->
        if pid != sender do
          send(pid, {:broadcast, message})
        end
      end)
    end)

    {:ok, state}
  end
end
