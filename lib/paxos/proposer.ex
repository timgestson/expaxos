defmodule Paxos.Proposer do
  @moduledoc """
    Proposer is spawned with each instance of Paxos
    Proposes a value to other nodes.
    Node must believe it is a leader in order to propose
    a value.
    Phases:
      Prepare
      Accept
  """

  use GenFSM.Behaviour
 
  defrecord State, 
    instance: 0, value: nil, leader: nil, 
    nodeid: 0, nodes: 0, round: 1, 
    promises: 0, accepts: 0, votes: 0,
    acceptors: [], promisers: [], 
    hab: nil, ballot: 0 do
      def ballot_calc(state) do
        list = Enum.sort(state.nodes)
        index = Enum.find_index(list, fn(node) ->
          node == state.nodeid
        end)
        index = index + 1
        length(state.nodes) * state.round + index
      end
      def majority(state) do
        length(state.nodes) / 2 
      end
      def prepare_message(state) do
        Paxos.Messages.PrepareReq.new(instance: state.instance, 
                    ballot: state.ballot, 
                    nodeid: state.nodeid)
      end
      def accept_message(state) do
        Paxos.Messages.AcceptReq.new(instance: state.instance,
                    ballot: state.ballot,
                    nodeid: state.nodeid,
                    value: state.value)
      end
    end
  
  def start_link(instance, value, leader, nodes) do  
    :gen_fsm.start_link(__MODULE__, [instance, value, leader, Node.self, nodes], [])
  end

  def message(pid, message) do
    :gen_fsm.send_event(pid, message) 
  end

  def init([instance, value, leader, nodeid, nodes]) do
    state = State.new(instance: instance, value: value, leader: leader, nodeid: nodeid, nodes: nodes)
    state = state.update(ballot: state.ballot_calc)
    case leader do
      true ->
        #skip prepare phase
        Paxos.Node.broadcast(state.accept_message)
        accept_timeout(state.ballot)
        {:ok, :accept, state}
      _ ->
        Paxos.Node.broadcast(state.prepare_message)
        prepare_timeout(state.ballot)
        {:ok, :prepare, state}
    end
  end
  #respond to incoming prepare request responses
  #if its the most current ballot of course
  def prepare(Paxos.Messages.PrepareResp[ballot: ballot, 
                          hab: hab, 
                          hav: value,
                          nodeid: id], state = State[ballot: stateballot] ) 
    when ballot == stateballot do 
      if Enum.member?(state.promisers,id) == false do
        state = state.update( promisers: List.concat(state.promisers, [id]))
        #quorem has accepted a higher value before
        #this means that you can no longer put your 
        #value up for a vote
        if value !== nil and hab > state.hba do
          state = state.update(value: value)
          #should now reenqueue the value that was 
          #going to be proposed
        end
        state = state.update(promises: state.promises + 1)    
        case state.promises >= state.majority do
          true->
            Paxos.Node.broadcast(state.accept_message)
            accept_timeout(state.ballot)
            {:next_state, :accept, state}
          _->         
            {:next_state, :prepare, state}
        end   
    else
      {:next_state, :prepare, state}
    end 
  end

  def prepare(_message, state) do
    {:next_state, :prepare, state}
  end

  def accept(Paxos.Messages.AcceptResp[ballot: ballot, nodeid: id], state=State[ballot: stateballot]) when ballot == stateballot do 
    if Enum.member?(state.acceptors,id) == false do
      state = state.update(accepts: state.accepts + 1, acceptors: state.acceptors ++ [id])
      case state.accepts > state.majority do
        true->
          Paxos.Node.learn(state.value)
          {:stop, :normal, state}
        _->
          {:next_state, :accept, state}
      end
    else
      {:next_state, :accept, state}
    end
  end
   
  def accept(_message, state) do
    {:next_state, :accept, state}
  end
 
  def handle_event(_message, state_name, state) do
    {:next_state, state_name, state}
  end
  
  def handle_info({:ptimeout, ballot}, :prepare, state=State[ballot: stateballot]) when ballot == stateballot do
    state = state.update(round: state.round + 1)  
    state = state.update(ballot: state.ballot_calc)    
    Paxos.Node.broadcast(state.prepare_message)
    prepare_timeout(state.ballot)
    {:next_state, :prepare, state}
  end

  def handle_info({:atimeout, ballot}, :accept, state=State[ballot: stateballot]) when ballot == stateballot do
    state = state.update(round: state.round + 1)
    state = state.update(ballot: state.ballot_calc)    
    Paxos.Node.broadcast(state.prepare_message)
    prepare_timeout(state.ballot)
    {:next_state, :prepare, state}
  end

  def handle_info(_, state_name, state) do
    {:next_state, state_name, state}
  end

  defp prepare_timeout(ballot) do
    :erlang.send_after(3000, Process.self(), {:ptimeout, ballot})
  end

  defp accept_timeout(ballot) do
    :erlang.send_after(3000, Process.self(), {:atimeout, ballot})
  end
  
end
