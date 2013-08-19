defmodule Paxos.Transport do
  use GenServer.Behaviour
  defrecord State, test: 1

  def send(node, payload) do
    :gen_server.call(:transport, {:send, node, payload})
  end

  def broadcast(payload) do
    :gen_server.cast(:transport, {:broadcast, payload})
  end

  def start_link() do
    :gen_server.start_link({:local,:transport}, __MODULE__, [],[])
  end

  def init() do
    {:ok, []}
  end
 
  def handle_call({:send, node, message}, _from, state) do
    IO.puts(inspect(node))
    {:transport, node} <- {:message, message}
    {:reply, :ok, state}
  end

  def handle_cast({:broadcast, message}, state) do
    Enum.each(Node.list ++ [Node.self], fn(node) ->
      {:transport, node} <- {:message, message}
    end)
    {:noreply, state}
  end

  def handle_info({:message, message}, state) do
    spawn(__MODULE__, :worker, [message])
    {:noreply, state}
  end

  def worker(message = Paxos.Messages.PrepareReq[instance: instance]) do
      IO.puts("message")       
      Paxos.Coordinator.message(message) 
  end

  def worker(message = Paxos.Messages.PrepareResp[instance: instance]) do
      IO.puts("message")        
      Paxos.Coordinator.message(message) 
  end

  def worker(message = Paxos.Messages.AcceptReq[instance: instance]) do
      IO.puts("message")        
      Paxos.Coordinator.message(message) 
  end

  def worker(message = Paxos.Messages.AcceptResp[instance: instance]) do
      IO.puts("message")        
      Paxos.Coordinator.message(message) 
  end

  def worker(_) do

  end
end
