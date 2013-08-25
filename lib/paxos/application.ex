defmodule Paxos.Application do
  use Application.Behaviour

  def start([nodes, file], _) do
    Paxos.Disk_log.start_link(file)
    instance = Paxos.Disk_log.get_instance
    IO.puts(inspect(instance))
    Paxos.Node.start_link(nodes, instance)
    :ok    
  end

  def stop do

  end
end
