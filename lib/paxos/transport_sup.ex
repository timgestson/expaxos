defmodule Paxos.Transport_Sup do
  use Supervisor.Behaviour

  def start_link do
    :supervisor.start_link(__MODULE__, [])
  end  

  def init([]) do
    IO.puts("here")
    children = [ worker(Paxos.Transport, []) ]
    supervisor children, strategy: :one_for_one
  end

end
