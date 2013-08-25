defmodule Paxos do
  
  def start(nodes, log) do
    Paxos.Application.start([nodes, log], 0)
  end

  def submit(value) do
    Paxos.Node.submit(value)
  end

  def status() do
    Paxos.Node.get_status
  end

  def read() do
    Paxos.Disk_log.chunk
  end

end
