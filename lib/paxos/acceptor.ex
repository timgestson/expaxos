defmodule Paxos.Acceptor do
  use GenServer.Behaviour

  defrecord State, promise: 0, accepted: 0

  def start_link() do
    :gen_server.start_link({:local,__MODULE__}, __MODULE__, [], [])
  end

  def vote({type, ballot}) do
    :gen_server.call(__MODULE__, {type, ballot})
  end

  def init([]) do
    state = State.new()
    {:ok, state}
  end

  def call({:prepare, ballot}, state) do
    case ballot < state.accepted do
      false ->
        state.update(promise: ballot)
        {:reply, {:yeh, state.accepted}, state}
      _ ->
        {:reply, :neh, state}
    end
  end

  def call({:accept, ballot}, state) do  
    case ballot < state.accepted do
      false ->
        state.update()
        {:reply, :yeh, state}
      _ ->
        {:reply, :neh, state}
    end
  end

end
