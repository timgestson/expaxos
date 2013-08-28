Code.require_file "test_helper.exs", __DIR__ 

defmodule Paxos.Acceptor.Test do
  use ExUnit.Case
 
  setup do
    Paxos.start([],"test_acceptor")
  end 

  test "acceptor has recieved higher ballot prepare" do
    request = Paxos.Messages.PrepareReq.new(ballot: 2, nodeid: :"nohost@nohost")
    state = Paxos.Acceptor.State.new(hpb: 3)
    {:noreply, newstate} = Paxos.Acceptor.handle_cast(request, state)
    assert newstate.hpb === 3
  end

  test "acceptor hasn't recieved higher ballot prepare" do 
    request = Paxos.Messages.PrepareReq.new(ballot: 2, nodeid: Node.self)
    state = Paxos.Acceptor.State.new(hpb: 1)
    {:noreply, newstate} = Paxos.Acceptor.handle_cast(request, state)
    assert newstate.hpb === 2
  end

  test "acceptor recieved lower ballot accept" do 
    request = Paxos.Messages.AcceptReq.new(ballot: 2, value: 3, nodeid: Node.self)
    state = Paxos.Acceptor.State.new(hpb: 3, hav: nil, hab: nil)
    {:noreply, newstate} = Paxos.Acceptor.handle_cast(request, state)
    assert newstate.hpb === 3
    assert newstate.hav === nil
    assert newstate.hab === nil
  end

  test "acceptor recieves equal ballot accept" do 
    request = Paxos.Messages.AcceptReq.new(ballot: 3, value: 3, nodeid: Node.self)
    state = Paxos.Acceptor.State.new(hpb: 3, hav: nil, hab: nil)
    {:stop, :normal, newstate} = Paxos.Acceptor.handle_cast(request, state)
    assert newstate.hpb === 3
    assert newstate.hav === 3
    assert newstate.hab === 3
  end

end
