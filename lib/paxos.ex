defmodule Paxos do

  defrecord Command, epoch: nil, command: nil 
  
  def start(nodes, log) do
    Paxos.Application.start([nodes, log], 0)
  end

  def submit(command) do
    command 
    |> create_command
    |> Paxos.Node.submit
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
    Paxos.Logger.add_handler(module, args)
  end

  defp create_command(command) do
    Paxos.Command.new(command: command, epoch: epoch)
  end

  defp epoch do
    now = :erlang.now 
    |> :calendar.now_to_universal_time
    |> :calendar.datetime_to_gregorian_seconds
    now - 719528 * 24 * 3600
  end

end

