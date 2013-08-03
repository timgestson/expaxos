defmodule Paxos.Propose do
  use GenFSM.Behaviour

  #states = [ listening, proposing, accepting]

  defrecord State, key: nil, value: nil, ballot: 0, prepare: HashSet.new(), accept: Hashset.new()

  def start_link do
    :gen_fsm.start_link({:local, __MODULE__}, __MODULE__, [], [])
  end

  def put(key, value) do

  end

  def campaign(node) do
    
  end

  def init([]) do

  end

  def listening({:put, key, value}, state) do
    
  end

  def proposing({:put, key, value, state) do

  end

  def accepting({:put, key, value, state) do

  end

  def handle_info do
    
  end

end
