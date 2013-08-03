defmodule Paxos do
  use GenServer.Behaviour  
  
  defrecord State, 
    nodes: []

  def start_link do
    :gen_server.start_link({:local, __MODULE__},__MODULE__, [], [])
  end

  def init([]) do
    {:ok, State.new(nodes: Node.list())}
  end

  def propose(key, value) do
    :gen_server.cast(__MODULE__, {:propose, key, value})
  end

  def handle_cast({:propose, key, value}) do
    
  end

end
