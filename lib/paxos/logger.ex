defmodule Paxos.Logger do
  use GenServer.Behaviour

  defrecord State, log: "/data/log"

  def log(value, instance) do
    :gen_server.call(:logger, {:log, value, instance})
  end
  
  def start_link() do
    :gen_server.start_link({:local, :logger},__MODULE__, [],[]) 
  end

  def init([]) do
    {:ok, State.new}
  end

  def handle_call({:log, value, instance}, _from, state) do
    IO.puts("log: ")
    IO.puts(inspect(value))
    IO.puts("instance: ")
    IO.puts(instance)
    {:reply, :ok, state}
  end
end
