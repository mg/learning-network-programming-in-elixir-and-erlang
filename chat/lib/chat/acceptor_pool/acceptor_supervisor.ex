defmodule Chat.AcceptorPool.AcceptorSupervisor do
  use Supervisor

  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    pool_size = Keyword.get(opts, :pool_size, 10)
    listen_socket = Keyword.fetch!(opts, :listen_socket)

    children =
      for index <- 1..pool_size do
        spec = {Chat.AcceptorPool.Acceptor, listen_socket}
        Supervisor.child_spec(spec, id: "acceptor_#{index}")
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
