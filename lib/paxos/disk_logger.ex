defmodule Paxos.Disk_log do
  use GenServer.Behaviour

  defrecord Entry, instance: nil, command: nil

  defrecord State, log: nil

  def start_link(file) do
    :gen_server.start_link({:local, __MODULE__}, __MODULE__, [file], [])
  end

  def log(value, instance) do
    :gen_server.call(__MODULE__, {:log, value, instance})
  end

  def chunk do
    :gen_server.call(__MODULE__, :chunk)
  end

  def get_instance do
   case chunk do
      {_cont, list} ->
        last = Enum.reverse(list) |> Enum.first
        IO.puts(inspect(last))
        last.instance + 1
      :eof ->
        1
   end
  end

  def catch_up(last) do
    :gen_server.call(__MODULE__,{:catch_up, last})
  end

  def init([file]) do
    file = Path.join(__DIR__, file)
    log = case :disk_log.open([{:name, :log},{:file, binary_to_list(file)}]) do
      {:ok, log} -> log
      {:repaired, log, _bytes, _bad}-> log
    end
    :disk_log.sync(log)
    {:ok, State.new(log: log)}
  end

  def handle_call({:log, value, instance}, _from, state) do
    entry = Entry.new(instance: instance, command: value)
    :disk_log.log(state.log, entry)
    {:reply, :ok, state}
  end

  def handle_call(:chunk, _from, state) do
    reply = :disk_log.chunk(state.log, :start)
    {:reply, reply, state}
  end

  def handle_call({:catch_up, last}, _from, state) do
    {_cont, list} = :disk_log.chunk(state.log, :start)
    reply = Enum.filter(list, fn(elem) ->
      elem.instance > last
    end)
    {:reply, {:ok, reply}, state}
  end

end
