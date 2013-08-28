defmodule Paxos.Logger do
  use GenEvent.Behaviour

  defrecord Entry, instance: nil, command: nil

  defrecord State, log: nil

  def start_link(log) do
    {:ok, pid} = :gen_event.start_link({:local, :log_event})
    :gen_event.add_sup_handler(:log_event, __MODULE__, [log])
    {:ok, pid}
  end

  def add_handler(handler, args) do
    :gen_event.add_handler(:log_event, handler, args)
  end

  def delete_handle(handler, args) do
    :gen_event.delete_hander(:log_event, handler, args)
  end

  def log_entry(command, instance) do
    :gen_event.sync_notify(:log_event, {:log_entry, command, instance})
  end

  def chunk do
    :gen_event.call(:log_event, __MODULE__, :chunk)
  end

  def chunk(cont) do
    :gen_event.call(:log_event, __MODULE__, {:chunk, cont})
  end
  
  def chunk(cont, num) do
    :gen_event.call(:log_event, __MODULE__, {:chunk, cont, num})
  end

  def get_instance do
   case chunk do
      {_cont, list} ->
        last = Enum.reverse(list) |> Enum.first
        last.instance + 1
      :eof ->
        1
   end
  end

  def catch_up(last) do
    :gen_event.call(:log_event, __MODULE__,{:catch_up, last})
  end

  def init([file]) do
    file = Path.join([__DIR__, "..","..","logs",file])
    log = case :disk_log.open([{:name, :log},{:file, binary_to_list(file)}]) do
      {:ok, log} -> log
      {:repaired, log, _bytes, _bad}-> log
    end
    :disk_log.sync(log)
    {:ok, State.new(log: log)}
  end

  def handle_event({:log_entry, value, instance}, state) do
    entry = Entry.new(instance: instance, command: value)
    :disk_log.log(state.log, entry)
    {:ok, state}
  end

  def handle_call(:chunk, state) do
    reply = :disk_log.chunk(state.log, :start)
    {:ok, reply, state}
  end

  def handle_call({:chunk, num}, state) when is_integer(num) do 
    reply = :disk_log.chunk(state.log, :start, num)
    {:ok, reply, state}
  end

  def handle_call({:chunk, cont}, state) do
    reply = :disk_log.chunk(state.log, cont)
    {:ok, reply, state}
  end

  def handle_call({:chunk, cont, num}, state) do
    reply = :disk_log.chunk(state.log, cont, num)
    {:ok, reply, state}
  end

  def handle_call({:catch_up, last}, state) do
    {_cont, list} = :disk_log.chunk(state.log, :start)
    reply = Enum.filter(list, fn(elem) ->
      elem.instance > last
    end)
    {:ok, {:ok, reply}, state}
  end

end
