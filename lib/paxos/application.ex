defmodule Paxos.Application do
  use Application.Behaviour

  def start([nodes, file], _) do
    Paxos.Event_sup.start_link(file)
    Paxos.Node_sup.start_link(nodes)
    :ok    
  end

  def stop do

  end
end
