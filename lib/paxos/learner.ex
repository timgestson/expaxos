defmodule Paxos.Learner do
  use GenServer.Behaviour

  alias Paxos.Messages.LearnReq, as: LearnReq

  defrecord State, instance: nil, value: nil
    
  def start_link(instance) do
    :gen_server.start_link(__MODULE__, [instance], [])
  end

  def learn(pid, value) do
    :gen_server.cast(pid, {:learn, value})
  end

  def message(pid, message) do
    :gen_server.cast(pid, {:message, message})
  end

  def init([instance]) do
    {:ok, State.new(instance: instance)}    
  end

  def handle_cast({:learn, value}, state) do
    IO.puts("boradcasting learn")
    Paxos.Node.broadcast(LearnReq.new(instance: state.instance, nodeid: Node.self, value: value))
    {:noreply, state}
  end

  def handle_cast({:message, message=LearnReq[]}, state) do
    IO.puts("logging")
    Paxos.Node.log(message.value)
    {:stop, :normal, state}
  end
  
end
