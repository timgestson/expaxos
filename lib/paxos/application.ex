defmodule Paxos.Application do
  use Application.Behaviour

  def start([nodes, file], _) do
    Paxos.Events.Internal.start_link(file)
    Paxos.Events.External.start_link
    Paxos.Node_sup.start_link(nodes)
    :ok    
  end

  def stop do

  end
end
