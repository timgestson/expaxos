defmodule Paxos.Event_sup do
  use Supervisor.Behaviour

  # A convenience to start the supervisor
  def start_link(log) do
    :supervisor.start_link(__MODULE__, log)
  end

  # The callback invoked when the supervisor starts
  def init(log) do
    children = [ 
                 worker(Paxos.Events.Internal, [log]), 
                 worker(Paxos.Events.External, []) 
               ]
    supervise children, strategy: :one_for_one
  end
end

