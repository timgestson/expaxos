defmodule Paxos.Logger do
  use GenEvent.Behaviour

  defrecord Entry, instance: nil, command: nil
  defrecord SnapEntry, path: nil


  defrecord State, log: nil do
    def log_file(state) do
      Path.join([__DIR__, "..","..","logs",state.log])
    end
    def snapshot_file(state) do
      Path.join([__DIR__, "..","..","logs", integer_to_binary(Paxos.epoch)])
    end
  end

  def start_link(log) do
    Paxos.Events.Internal.add_sup_handler(__MODULE__, [log])
  end

  def log_entry(command, instance) when command == :heartbeat do
    Paxos.Events.Internal.log(command, instance)
  end

  def log_entry(command, instance) do
    Paxos.Events.Internal.log(command, instance)
    Paxos.Events.External.log(command)
  end

  def chunk do
    Paxos.Events.Internal.call(__MODULE__, :chunk)
  end

  def chunk(cont) do
    Paxos.Events.Internal.call(__MODULE__, {:chunk, cont})
  end
  
  def chunk(cont, num) do
    Paxos.Events.Internal.call(__MODULE__, {:chunk, cont, num})
  end

  def get_last do
    Paxos.Events.Internal.call(__MODULE__, :get_last)
  end

  def get_instance do
   case get_last do
      :eof ->
        1
      last ->
        last.instance + 1
   end
  end

  def catch_up(last) do
    Paxos.Events.Internal.call(__MODULE__,{:catch_up, last})
  end

  def snapshot_handle() do
    Paxos.Events.Internal.call(__MODULE__, :snapshot_handle)
  end

  def snapshot_submit(handle) do
    Paxos.Events.Internal.call(__MODULE__, {:snapshot_submit, handle})
  end

  def playback() do
    Paxos.Events.Internal.call(__MODULE__, :playback)
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

  def handle_event({:log, value, instance}, state) do
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

  def handle_call(:get_last, state) do
    {:ok, reply, _state} = handle_call(:chunk, state)
    answer = case reply do
      {_cont, list} ->
        list 
        |> Enum.reverse
        |> Enum.first
      :eof ->
        :eof
    end
    {:ok, answer, state}
  end

  #do this more efficiently
  def handle_call({:catch_up, last}, state) do
    {_cont, list} = :disk_log.chunk(state.log, :start)
    reply = Enum.filter(list, fn(elem) ->
      elem.instance > last
    end)
    {:ok, {:ok, reply}, state}
  end

  def handle_call(:snapshot_handle, state) do
    inst = case handle_call(:get_last, state) do
      {:ok, Entry[instance: instance], _state} ->
        instance
      {:ok, :eof, _state}->
        0
    end
    {:ok, {state.snapshot_file, instance}, state}
  end

  def handle_call({:snapshot_submit, {file, instance}}, state) do
    {:ok, {:ok, list}, _state} = handle_call({:catch_up, instance}, state)
    IO.puts(inspect(list))
    :disk_log.truncate(state.log)
    IO.puts("here")
    :disk_log.log(state.log, SnapEntry.new(path: file))
    Enum.each(list, fn(item)->
      :disk_log.log(state.log, item)
    end)
    {:ok, :ok, state}
  end

  def handle_call(:playback, state) do 
    {:ok, log, _state} = handle_call(:chunk, state) 
    unless log == :eof do
      {_cont, list} = log
      Enum.each(list, fn(item)->
        case item do
          Entry[command: command] ->
            Paxos.Events.External.log(command)
          SnapEntry[path: path] ->
            Paxos.Events.External.snapshot(path)
         end
      end)
    end
  end

end
