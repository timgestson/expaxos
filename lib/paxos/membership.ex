
defmodule Paxos.Membership do
  use GenServer.Behaviour
  
  defrecord Replica, 
    ip: nil, 
    port: nil

  defrecord State,
    leader: :self,
    socket: nil,
    nodes: []
   
  def start_link do
    :gen_server.start_link({:local, __MODULE__}, __MODULE__, [], [])
  end
 
  def broadcast(message) do
    :gen_server.cast(__MODULE__, {:broadcast, message})
  end

  def init([replicas]) do
    :erlang.send_after(6000, Node.self(), :heartbeat)
    {:ok, socket} = :gen_udp.open(8000, [:binary, {:active, true}])
    {:ok, State.new(nodes: replicas, socket: socket)}
  end 

  def handle_cast({:broadcast, message}, State[nodes: addresses]) do
    Enum.map(addresses, fn(addr) ->
      
    end)
  end


end
