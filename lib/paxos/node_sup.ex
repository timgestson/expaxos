defmodule Paxos.Node_sup do
  use Supervisor.Behaviour

  # A convenience to start the supervisor
  def start_link(nodes) do
    :supervisor.start_link(__MODULE__, nodes)
  end

  # The callback invoked when the supervisor starts
  def init(nodes) do
    children = [ worker(Paxos.Node, [nodes]) ]
    supervise children, strategy: :one_for_one
  end
end

