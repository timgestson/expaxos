defmodule Paxos.Ballot do
  use GenServer.Behaviour

  defrecord State, ballots:1, node: nil

  def start_link(node) do
    :gen_server.start_link({:local,__MODULE__},__MODULE__, [node],[])
  end

  def get do
    :gen_server.call(__MODULE__, :get)
  end

  def init([node]) do
    {:ok, State.new(node: node)}
  end

  def handle_call(:get, _from, state) do
    {:reply, state.ballots * state.node, state.update(ballots:state.ballots + 1)}
  end

end
