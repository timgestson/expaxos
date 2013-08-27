defmodule Paxos.Log_sup do
  use Supervisor.Behaviour

  # A convenience to start the supervisor
  def start_link(log) do
    :supervisor.start_link(__MODULE__, log)
  end

  # The callback invoked when the supervisor starts
  def init(log) do
    children = [ worker(Paxos.Logger, [log]) ]
    supervise children, strategy: :one_for_one
  end
end
