defmodule Paxos.Learner do
  use GenServer.Behaviour

  defrecord State, learners: 0, lessons: HashDict.new()

  defrecord Lesson, key: nil, value: nil, acks: 0

  def start_link() do
    :gen_server.start_link({:local, __MODULE__}, __MODULE__, [], [])
  end

  def learn(key, value) do
    :gen_server.cast(__MODULE__, {:learn, key, value})
  end

  

  def init([learners]) do
    {:ok, State.new(learners: learners)}
  end  

  def cast({:learn, key, value}, state) do
    #Paxos.Transport.broadcast({key, value, Node.self()})
    state = state.update(lessons: HashDict.put(state.lessons, key, {value, Node.self()}))
    {:noreply, state}
  end

end
