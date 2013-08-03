defmodule Paxos.Acceptor do
  
  Record.import Paxos.Proposer.PrepareReq, as: :PrepareReq
  Record.import Paxos.Proposer.PrepareResp, as: :PrepareResp
  Record.import Paxos.Proposer.AcceptReq, as: :AcceptReq
  Record.import Paxos.Proposer.AcceptResp, as: :AcceptResp

  use GenServer.Behaviour

  defrecord State, instance: nil, hpb: 0, hab: nil, hav: nil do
    #highest promised ballot
    #highest accepted ballot
    #highest accepted value
    def prepare_message(ballot, state) do
      PrepareResp.new(instance: state.instance, ballot: ballot, 
                      nodeid: state.nodeid, hab: state.hab,
                      hav: state.hav)
    end
    def accept_message(ballot, state) do
      AcceptResp.new(instance: state.instance, ballot: ballot, 
                    nodeid: state.nodeid, value: state.hav)
    end
  

  def start_link(instance) do
    :gen_server.start_link(__MODULE__, [instance], [])
  end
  
  def message(instance, message) do
    case :ets.lookup(:instances, instance) do
      [{^instance, pid, value}] when is_pid(pid) ->
        :gen_server.cast(pid, message)
        :ok
      [{^instance, pid, value}]->
        :err
      _ ->
        pid = start_link(instance)
        :ets.insert_new(:instances, {instance, pid, nil})
        :gen_server.cast(pid, message)
        :ok
    end
  end
  
  def init([instance]) do
    state = State.new()
    {:ok, state}
  end

  def handle_cast(PrepareReq[ballot: ballot, nodeid: nodeid], state) 
  when ballot > state.hpb do
    Paxos.Transport.send(nodeid, state.prepare_message(ballot))
  end

  def handle_cast(AcceptReq[ballot: ballot, nodeid: nodeid, value: value], state) 
  when ballot > state.hpb do
      state.update(accepted: value)
      #tell local learner?
      #stop process after inactive period?
      Paxos.Transport.send(nodeid, state.accept_message(ballot))
  end

end
