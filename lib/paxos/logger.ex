defmodule Paxos.Logger do
  use GenServer.Behaviour

  defrecord State, instance: 1, log: "/data/log"

  def log(value) do
    :gen_server.call(:logger, {:log, value})
  end

  def get_instance() do
    :gen_server.call(:logger, {:get_instance})
  end
  
  def start_link() do
    :gen_server.start_link({:local, :logger},__MODULE__, [],[]) 
  end

  def init([]) do
    {:ok, State.new}
  end

  def handle_call({:log, value}, _from, state) do
    IO.puts("log: ")
    IO.puts(inspect(value))
    IO.puts("instance: ")
    IO.puts(state.instance)
    state = state.update(instance: state.instance + 1)
    {:reply, :ok, state}
  end


  def handle_call({:get_instance}, _from, state=State[instance: instance]) do
    {:reply, instance, state}
  end 

end
