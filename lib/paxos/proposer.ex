defmodule Paxos.Proposer do
  use GenFSM.Behaviour

  defrecord State, key: nil, value: nil, majority: nil, prepvotes: 0 , acceptvotes: 0
  
  def init([key, value, majority]) do
    ballot = Paxos.Ballot.get
    state = State.new([key: key, value: value, majority: majority])
    Paxos.Transport.broadcast(Kernel.term_to_binary({:prepare, ballot, Node.self()}))
    {:ok, :prepare, state}
  end

  def prepare({:prepare, :vote}, state) do
    state = state.update(prepvotes: (state.prepvotes + 1))
    case state.prepvotes >= state.majority do
      true ->
        #Paxos.Transport.broadcast({:accept, state.ballot, {state.key, state.value}, Node.self()})
        {:next_state, :accept, state}
      _ ->
        {:next_state, :prepare, state}
    end
  end  

  def prepare(_, state) do
    {:next_state, :prepare, state}
  end

  def accept({:accept, :vote}, state) do
    state = state.update(acceptvotes: (state.acceptvotes + 1))
    case state.acceptvotes >= state.majority do
      true ->
        {:stop, :normal, :ok, state}
      _->
        {:next_state, :accept, state}
    end 
  end

  def accept(_, state) do
    {:next_state, :accept}
  end

end
