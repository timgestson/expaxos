defmodule Paxos.Acceptor do
  @moduledoc """
    Acceptor is spawned with each instance of Paxos
    Handles:
      Prepare Requests
      Accept Requests
  """
  use GenServer.Behaviour

  defrecord State, instance: nil, hpb: 0, hab: nil, hav: nil, nodeid: nil do
    #highest promised ballot
    #highest accepted value
    def prepare_message(ballot, state) do
      Paxos.Messages.PrepareResp.new(instance: state.instance, ballot: ballot, nodeid: state.nodeid, hab: state.hab, hav: state.hav)
    end
    def accept_message(ballot, state) do
      Paxos.Messages.AcceptResp.new(instance: state.instance, ballot: ballot, nodeid: state.nodeid, value: state.hav)
    end
  end  

  def start_link(instance) do
    :gen_server.start_link(__MODULE__, [instance], [])
  end

  def message(pid, message) do
    :gen_server.cast(pid, message)
  end
   
  def init([instance]) do
    state = State.new(instance: instance, nodeid: Node.self())
    {:ok, state}
  end

  def handle_cast(Paxos.Messages.PrepareReq[ballot: ballot, nodeid: nodeid], state=State[hpb: hpb]) 
  when ballot > hpb do
    Paxos.Node.send(nodeid, state.prepare_message(ballot))
    state = state.update(hpb: ballot)
    {:noreply, state}
  end

  def handle_cast(Paxos.Messages.AcceptReq[ballot: ballot, nodeid: nodeid, value: value], state=State[hpb: hpb]) 
  when ballot >= hpb do
      state = state.update(hav: value, hab: ballot)
      #tell local learner?
      Paxos.Node.send(nodeid, state.accept_message(ballot))
      {:stop, :normal, state}
  end

  def handle_cast(_Message, state) do
    {:noreply, state}
  end
end
