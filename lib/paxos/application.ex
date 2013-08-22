defmodule Paxos.Application do
  use Application.Behaviour

  def start( _, _) do
    Paxos.Logger.start_link
    Paxos.Transport.start_link
   answer =  Paxos.Coordinator.init
    :ok    
  end

  def stop do

  end
end
