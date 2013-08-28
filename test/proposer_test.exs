Code.require_file "test_helper.exs", __DIR__

defmodule Paxos.Proposer.Test do
  use ExUnit.Case

  alias Paxos.Proposer.State, as: State
  alias Paxos.Proposer, as: Prop
  alias Paxos.Messages.PrepareResp, as: PrepResp
  alias Paxos.Messages.AcceptResp, as: AccResp

  setup do
    Paxos.start([],"test_proposer")
  end

  test "init while leader skips prepare phase" do
    {:ok, next_state, state} = Prop.init([1, 3, true, Node.self, [Node.self]])
    assert next_state === :accept
  end

  test "init while follower does prepare phase" do
    {:ok, next_state, state} = Prop.init([1, 3, false, Node.self, [Node.self]])
    assert next_state === :prepare
  end

  test "ballot calc works" do
    state =  State.new(round: 3, nodes: ["dumb", "dumber", Node.self], nodeid: Node.self)
    assert 10 === state.ballot_calc
  end

  test "prepare votes under majority same value" do
    state = State.new(promises: 0, nodes: [Node.self, Node.self, Node.self], ballot: 5, promisers: [], value: 9)
    req = PrepResp.new(ballot: 5, value: nil, nodeid: Node.self, hab: nil, hav: nil)
    {:next_state, state_name, newstate} = Prop.prepare(req, state)
    assert state_name === :prepare
    assert newstate.promisers === [Node.self]
    assert newstate.promises === 1
    assert newstate.value === 9
  end

  test "prepare votes under majority new value" do 
    state = State.new(promises: 0, nodes: [Node.self, Node.self, Node.self], ballot: 5, promisers: [], value: 9, hab: 0)
    req = PrepResp.new(ballot: 5, value: nil, nodeid: Node.self, hab: 8, hav: 20)
    {:next_state, state_name, newstate} = Prop.prepare(req, state)
    assert state_name === :prepare
    assert newstate.promisers === [Node.self]
    assert newstate.promises === 1
    assert newstate.value === 20
  end

  test "prepare votes at majority new value" do 
    state = State.new(promises: 1, nodes: [Node.self, Node.self, Node.self], ballot: 5, promisers: [:dumb], value: 9, hab: 0)
    req = PrepResp.new(ballot: 5, value: nil, nodeid: Node.self, hab: 8, hav: 20)
    {:next_state, state_name, newstate} = Prop.prepare(req, state)
    assert state_name === :accept
    assert newstate.promisers === [:dumb, Node.self]
    assert newstate.promises === 2
    assert newstate.value === 20
  end
  
  test "prepare votes at majority same value" do 
    state = State.new(promises: 1, nodes: [Node.self, Node.self, Node.self], ballot: 5, promisers: [:dumb], value: 9, hab: 0)
    req = PrepResp.new(ballot: 5, value: nil, nodeid: Node.self, hab: nil, hav: nil)
    {:next_state, state_name, newstate} = Prop.prepare(req, state)
    assert state_name === :accept
    assert newstate.promisers === [:dumb, Node.self]
    assert newstate.promises === 2
    assert newstate.value === 9
  end
  
  test "accept message for previous ballot" do
    state = State.new(accepts: 0, nodes: [Node.self, Node.self, Node.self], ballot: 5, acceptors: [], value: 6)
    req = AccResp.new(ballot: 5, nodeid: Node.self)
    {:next_state, state_name, newstate} = Prop.accept(req, state)
    assert state_name === :accept
    assert newstate.acceptors === [Node.self]
  end

end

