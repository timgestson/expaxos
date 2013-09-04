defmodule Paxos do

  defrecord Command, epoch: nil, command: nil 
  
  def start(nodes, log) do
    Paxos.Application.start([nodes, log], 0)
  end

  def call(command) do
    newcommand = submit(command)
    spawn(Paxos.Waiting, :start_link, [newcommand, Process.self])
    receive do
      :confirm ->
        :ok
      :error ->
        :ok
    end
  end

  def cast(command) do
    submit(command)
    :ok
  end

  defp submit(command) do
    newcommand = command 
    |> create_command
    newcommand
    |> Paxos.Node.submit
    newcommand
  end

  def status() do
    Paxos.Node.get_status
  end

  def read() do
    Paxos.Logger.chunk
  end

  def read(num) when is_integer(num) do
    Paxos.Logger.chunk(num)
  end

  def read(cont) do
    Paxos.Logger.chunk(cont)
  end
  
  def read(cont, num) do
    Paxos.Logger.chunk(cont, num)
  end

  def add_handler(module, args) do
    Paxos.Events.External.add_handler(module, args)
  end

  def snapshot_prepare() do
    Paxos.Logger.snapshot_handle
  end

  def snapshot_submit(handle) do
    Paxos.Logger.snapshot_submit(handle)
  end

  def playback() do
    Paxos.Logger.playback
  end

  defp create_command(command) do
    Paxos.Command.new(command: command, epoch: epoch)
  end

  def epoch do
    now = :erlang.now 
    |> :calendar.now_to_universal_time
    |> :calendar.datetime_to_gregorian_seconds
    now - 719528 * 24 * 3600
  end

end


defmodule Paxos.Waiting do
  use GenEvent.Behaviour
  defrecord State, command: nil, pid: nil

  def start_link(command, pid) do
    Paxos.Events.Internal.add_handler(__MODULE__, [command, pid])
  end

  def init([command, pid]) do
    :erlang.send_after(2000, Process.self(), :error)
    {:ok, State.new(command: command, pid: pid) }
  end

  def handle_event({:log, command, _instance}, 
    State[command: scommand, pid: pid]) 
    when scommand == command do
      pid <- :confirm 
    :remove_handler
  end
  
  def handle_event(event, state) do
    {:ok, state}
  end

  def handle_info(:error, state) do
    state.pid <- :error
    :remove_handler
  end
end
