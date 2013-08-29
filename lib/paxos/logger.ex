defmodule Paxos.Logger do
  use GenEvent.Behaviour

  defrecord Entry, instance: nil, command: nil

  defrecord State, log: nil do
    def log_file(state) do
      Path.join([__DIR__, "..","..","logs",state.log])
    end
    def snapshot_file(state) do
      Path.join([__DIR__, "..","..","snapshots",state.log])
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
    case chunk do
      {_cont, list} ->
        list 
        |> Enum.reverse
        |> Enum.first
      :eof ->
        :eof
    end
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
    temp = Paxos.Events.Internal.call(__MODULE__, :snapshot_handle)
    {temp, get_last}
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

  def handle_call({:catch_up, last}, state) do
    {_cont, list} = :disk_log.chunk(state.log, :start)
    reply = Enum.filter(list, fn(elem) ->
      elem.instance > last
    end)
    {:ok, {:ok, reply}, state}
  end

  def handle_call(:snapshot_handle, state) do
    epoch = Paxos.epoch
    file = Path.join([__DIR__, "..","..","snapshots",epoch])
    {:ok, file, state}
  end

  def handle_call({:snapshot_submit, {temp, instance}}, state) do
    path = state.snapshot_file
    if File.exists? path do
      File.rm! path
    end
    File.cp! temp, path
    :ok
  end

  def handle_call(:playback, state) do 
    path = state.snapshot_file
    if File.exists? path do
      Paxos.Events.External.snapshot(path)
    end
    {:ok, {_cont, list}, _state} = handle_call(:chunk, state) 
    unless list == :eof do
      Enum.each(list, fn(Entry[command: command])->
        Paxos.Events.External.log(command)
      end)
    end
  end

end
