Code.require_file "test_helper.exs", __DIR__

defmodule Paxos.Node.Test do
  use ExUnit.Case

  alias Paxos.Node.State, as: State
  alias Paxos.Node, as: Pnode
  alias Paxos.Messages, as: Msg
  alias Paxos.Logger.Entry, as: Entry
  alias :queue, as: Queue
  alias Paxos.Messages.PrepareReq, as: PrepReq 
  alias Paxos.Messages.AcceptReq, as: AccReq
  alias Paxos.Messages.LearnReq, as: LrnReq

  setup do
    Paxos.start([],"test_node")
  end
  


  test "submit as candidate empty queue" do
    event = {:submit, 10}
    state_name = :candidate
    state = State.new(queue: Queue.new, nodes: [Node.self])
    {:next_state, :candidate, newstate} = Pnode.handle_event(event, state_name, state)
    assert newstate.actors.proposer !== nil
    assert newstate.queue == Queue.from_list([10])
  end
  
  test "submit as candidate nonempty queue" do
    event = {:submit, 10}
    state_name = :candidate
    state = State.new(queue: Queue.from_list([2]), nodes: [Node.self])
    {:next_state, :candidate, newstate} = Pnode.handle_event(event, state_name, state)
    assert newstate.actors.proposer == nil
    assert newstate.queue == Queue.from_list([2, 10])
  end
  
  test "logging as leader value different than queue" do
    state = State.new(instance: 5, queue: Queue.from_list([5]), nodes: [Node.self])
    state_name = :leader
    event = {:log, 7}
    {:reply, :ok, new_state_name, new_state} = Pnode.handle_sync_event(event,:from, state_name, state)
    assert new_state_name == :leader
    assert new_state.queue == Queue.from_list([5])
    assert new_state.instance == 6
    assert new_state.actors.proposer !== nil
  end 

  test "logging as leader value same queue" do
    state = State.new(instance: 5, queue: Queue.from_list([5]), nodes: [Node.self])
    state_name = :leader
    event = {:log, 5}
    {:reply, :ok, new_state_name, new_state} = Pnode.handle_sync_event(event, :from, state_name, state)
    assert new_state_name == :leader
    assert new_state.queue == Queue.new
    assert new_state.instance == 6
    assert new_state.actors.proposer == nil
  end
  
  test "logging as follower" do
    state = State.new(instance: 5, nodes: [Node.self])
    state_name = :follower
    event = {:log, 5}
    {:reply, :ok, new_state_name, new_state} = Pnode.handle_sync_event(event, :from, state_name, state)
    assert new_state_name == :follower
    assert new_state.instance == 6
    assert new_state.actors.proposer == nil
  end
  
  test "catching up as stragler" do
    state = State.new(instance: 4, catching_up: true)
    state_name = :stragler
    list = Enum.map([4,5,6,7], fn(i) ->
      Entry.new(instance: i, value: i)
    end)
    event = {:catch_up_log, list}
    {:reply, :ok, :follower, newstate} = Pnode.handle_sync_event(event, :from, state_name, state)
    assert newstate.instance == 8
    assert newstate.catching_up == false
  end

  test "accept request exposing node is a stragler" do
    state = State.new(instance: 4, catching_up: false, self: Node.self)
    req = AccReq.new(nodeid: Node.self, instance: 6)
    state_name = :follower
    {:next_state, next_name, newstate} = Pnode.handle_info( req, state_name, state)
    assert next_name == :stragler
    assert state.catching_up == true
    assert state.leader == Node.self
  end
  #
  #test "prepare request exposing node is a stragler" do
  #    state = State.new(instance: 4, catching_up: false, self: Node.self)
  #  req = PrepReq.new(nodeid: Node.self, instance: 6)
  #  state_name = :follower
  #  {:next_state, next_name, newstate} = Pnode.handle_info( req, state_name, state)
  #  assert next_name == :stragler
  #  assert state.catching_up == true
  #  assert state.leader == Node.self
 # end
  
  test "self sent Learn Req as Candidate" do
    state = State.new(instance: 8, self: Node.self, lease_num: 1)
    req = LrnReq.new(from: Node.self, instance: 8)
    state_name = :candidate
    {:next_state, next_name, next_state} = Pnode.handle_info(req, state_name, state)
    assert next_name == :leader
    assert next_state.leader == Node.self
    assert next_state.lease_num == 2
  end  

  # make sure propose messages kick off catching up also
  # handle queue handoff
  teardown do
    file = Path.join([__DIR__,  "..", "logs", "test_node"])
    File.rm! file
  end 
end
