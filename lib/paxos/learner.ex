defmodule Paxos.Learner do
  use GenServer.Behaviour

  alias Paxos.Messages.LearnReq, as: LearnReq
  alias Paxos.Messages.CatchupReq, as: CatchupReq
  alias Paxos.Messages.CatchupResp, as: CatchupResp


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

  def catch_up(message) do
    spawn(__MODULE__, :catch_up_spawn, [message])
  end

  def catch_up_spawn(CatchupReq[nodeid: from, last_instance: last]) do
    {:ok, list} = Paxos.Disk_log.catch_up(last)
    response = CatchupResp.new(response: list)
    Paxos.Node.send(from, response)
  end

  def init([instance]) do
    {:ok, State.new(instance: instance)}    
  end

  def handle_cast({:learn, value}, state) do
    Paxos.Node.broadcast(LearnReq.new(instance: state.instance, nodeid: Node.self, value: value))
    {:noreply, state}
  end

  def handle_cast({:message, message=LearnReq[]}, state) do
    IO.puts("logging")
    Paxos.Node.log(message.value)
    {:stop, :normal, state}
  end
  
  def handle_cast({:message, CatchupResp[response: values]},state) do
    Paxos.Node.catch_up_log(values)
    {:stop, :normal, state}
  end


end
