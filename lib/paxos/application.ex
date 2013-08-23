defmodule Paxos.Application do
  use Application.Behaviour

  def start(nodes, _) do
    Paxos.Logger.start_link
    Paxos.Node.start_link(nodes, 1)
    :ok    
  end

  def stop do

  end
end
