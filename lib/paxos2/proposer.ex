defmodule Paxos.Proposer do
  use GenFSM.Behaviour

  defrecord PrepareReq, instance: 0, ballot: 0, nodeid: nil

  defrecord AcceptReq, instance: 0, ballot: 0, nodeid: nil, value: nil

  defrecord PrepareResp, instance: 0, ballot: 0, nodeid: nil, hab: nil, hav: nil

  defrecord AcceptResp, instance: 0, ballot: 0, nodeid: nil
  
  defrecord State, 
    instance: 0, value: nil, leader: nil, 
    nodeid: 0, nodes: 0, round: 1, 
    promises: 0, accepts: 0, votes: 0, 
    hab: nil #highest accepted ballot
    do
      def ballot(state) do
        state.nodes * state.round - state.nodeid
      end
      def majority(state) do
        state.nodes / 2 + 1
      end
      def prepare_message(state) do
        PrepareReq.new(instance: state.instance, 
                    ballot: state.ballot, 
                    nodeid: state.nodeid)
      end
      def accept_message(state) do
        AcceptReq.new(instance: state.instance,
                    ballot: state.ballot,
                    nodeid: state.nodeid,
                    value: state.value)
      end
    end
  


  def init([slot, value, leader, nodeid, nodes]) do
    state = State.new(instance: instance, value: value, leader: leader, nodeid: nodeid, nodes: nodes)
    Paxos.Transport.broadcast(state.prepare_message)
    prepare_timeout(state.ballot)
    {:nextstate, :prepare, state}
  end

  #respond to incoming prepare request responses
  #if its the most current ballot of course
  def prepare(PrepareResp[ballot: ballot, 
                          hab: hab, 
                          hav: value], state) 
    when ballot == state.ballot do
    
    #quorem has accepted a higher value before
    #this means that you can no longer put your 
    #value up for a vote
    if value !== nil and hab > state.hba do
      state.update(value: value)
      #should now reenqueue the value that was 
      #going to be proposed
    end
    
    state.update(promises: state.promises + 1)    
    case state.promises >= state.majority do
      true->
        Paxos.Transport.broadcast(state.accept_message)
        {:next_state, :accept, state}
      _->         
        {:next_state, :prepare, state}
    end    
  end
  
  def handle_info({:ptimeout, ballot}, :prepare, state) 
    when ballot == state.ballot do
    state.update(round: state.round + 1)    
    Paxos.Transport.broadcast(state.prepare_message)
    prepare_timeout(state.ballot)
    {:next_state, :prepare, state}
  end

  def accept(AcceptResp[ballot: ballot], state) 
    when ballot == state.ballot do
    state.update(accepts: state.accepts + 1)
    case state.accepts >= state.majority do
      true->
        #value accepted our work is done
        #TODO: update instances registry
        {:stop, :normal, state}
      _->
        {:next_state, :accept, state}
    end
  end
  
  def handle_info({:atimeout, ballot}, :accept, state) 
    when ballot == state.ballot do
    state.update(round: state.round + 1)    
    Paxos.Transport.broadcast(state.prepare_message)
    prepare_timeout(state.ballot)
    {:next_state, :prepare, state}
  end

  defp prepare_timeout(ballot) do
    :erlang.send_after(3000, Node.self(), {:ptimeout, ballot})
  end

  defp accept_timeout(ballot) do
    :erlang.send_after(3000, Node.self(), {:atimeout, ballot})
  end

end
