defmodule Paxos do
  
  def start do
    Paxos.Application.start(0, 0)
  end

  def submit(value) do
    Paxos.Coordinator.submit(value)
  end

end
