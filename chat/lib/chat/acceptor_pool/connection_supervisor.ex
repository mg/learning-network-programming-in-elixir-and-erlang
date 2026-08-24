defmodule Chat.AcceptorPool.ConnectionSupervisor do
  use DynamicSupervisor

  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec start_connection(:gen_tcp.socket()) :: Supervisor.on_start()
  def start_connection(socket) do
    DynamicSupervisor.start_child(__MODULE__, {Chat.Connection, socket})
  end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
