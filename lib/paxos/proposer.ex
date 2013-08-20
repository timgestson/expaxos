defmodule Paxos.Proposer do
  use GenFSM.Behaviour
 
  defrecord State, 
    instance: 0, value: nil, leader: nil, 
    nodeid: 0, nodes: 0, round: 1, 
    promises: 0, accepts: 0, votes: 0, 
    hab: nil, ballot: 0 do
      def ballot_calc(state) do
        length(state.nodes) * state.round - state.nodeid
      end
      def majority(state) do
        length(state.nodes) / 2 + 1
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
  
  def start_link(instance, value) do  
    list = Node.list ++ [Node.self()]
    Enum.sort(list)
    id = Enum.find_index(list, fn(elem) -> 
      elem == Node.self() 
    end)
    :gen_fsm.start_link(__MODULE__, [instance, value, nil, Node.self, list], [])
  end

  def message(pid, message) do
    :gen_fsm.send_event(pid, message) 
  end

  def init([instance, value, leader, nodeid, nodes]) do
    state = State.new(instance: instance, value: value, leader: leader, nodeid: nodeid, nodes: nodes)
    state = state.update(ballot: 1)
    Paxos.Transport.broadcast(state.prepare_message)
    prepare_timeout(state.ballot)
    {:ok, :prepare, state}
  end

  #respond to incoming prepare request responses
  #if its the most current ballot of course
  def prepare(Paxos.Messages.PrepareResp[ballot: ballot, 
                          hab: hab, 
                          hav: value], state = State[ballot: stateballot] ) 
    when ballot == stateballot do
    
    #quorem has accepted a higher value before
    #this means that you can no longer put your 
    #value up for a vote
    if value !== nil and hab > state.hba do
      state = state.update(value: value)
      #should now reenqueue the value that was 
      #going to be proposed
    end
    IO.puts("votes recieved:")
    IO.puts(state.promises + 1) 
    state = state.update(promises: state.promises + 1)    
    case state.promises >= state.majority do
      true->
        Paxos.Transport.broadcast(state.accept_message)
        accept_timeout(state.ballot)
        {:next_state, :accept, state}
      _->         
        {:next_state, :prepare, state}
    end    
  end

  def accept(Paxos.Messages.AcceptResp[ballot: ballot], state=State[ballot: stateballot]) 
    when ballot == stateballot do
    state = state.update(accepts: state.accepts + 1)
    case state.accepts >= state.majority do
      true->
        #value accepted our work is done
        #TODO: update instances registry
        IO.puts("value accepted")
        IO.puts(state.value)
        {:stop, :normal, state}
      _->
        {:next_state, :accept, state}
    end
  end
  
  
  def handle_info({:ptimeout, ballot}, :prepare, state = State[ballot: stateballot]) 
    when ballot == stateballot do
    state = state.update(round: state.round + 1)    
    Paxos.Transport.broadcast(state.prepare_message)
    prepare_timeout(state.ballot)
    {:next_state, :prepare, state}
  end

  def handle_info({:atimeout, ballot}, :accept, state=State[ballot: stateballot]) 
    when ballot == stateballot do
    state = state.update(round: state.round + 1)
    state = state.update(ballot: state.ballot_calc)    
    Paxos.Transport.broadcast(state.prepare_message)
    prepare_timeout(state.ballot)
    {:next_state, :prepare, state}
  end

  defp prepare_timeout(ballot) do
    :erlang.send_after(3000, Process.self(), {:ptimeout, ballot})
  end

  defp accept_timeout(ballot) do
    :erlang.send_after(3000, Process.self(), {:atimeout, ballot})
  end
  
end
