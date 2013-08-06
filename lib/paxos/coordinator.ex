defmodule Paxos.Coordinator do
  use Paxos.Log.Behaviour

  alias Paxos.Messages.PrepareReq, as: PrepareReq
  alias Paxos.Messages.PrepareResp, as: PrepareResp
  alias Paxos.Messages.AcceptReq, as: AcceptReq
  alias Paxos.Messages.AcceptResp, as: AcceptResp

  def init do
    :ets.new(:instances, [:ordered_set, :named_table, :public, {:keypos, 1}])
  end  

  def message(message=PrepareReq[]) do
    message_acceptor(message)
  end

  def message(message=PrepareResp[]) do
    message_proposer(message)
  end

  def message(message=AcceptReq[]) do
    message_acceptor(message)
  end
  
  def message(message=AcceptResp[]) do
    message_proposer(message)
  end
  
  def submit(value) do
    instance = get_next
    start_instance(instance, value)
  end

  defp message_acceptor(message) do
    case get_instance(message.instance) do
      nil ->
        dict = start_instance(message.instance)
        pid = HashDict.fetch!(dict, :acceptor)
        Paxos.Acceptor.message(pid, message) 
      dict ->
        pid = HashDict.fetch!(dict, :acceptor)
        Paxos.Acceptor.message(pid, message)
    end
    :ok
  end

  defp message_proposer(message) do
    dict =  get_instance(message.instance)
    pid = HashDict.fetch!(dict, :proposer)
    Paxos.Acceptor.message(pid, message)
    :ok
  end

  defp start_instance(instance) do
    procs = HashDict.new
    HashDict.put(procs, Paxos.Acceptor.start_link(instance))
    insert_instance(instance, procs) 
    procs
  end

  defp start_instance(instance, value) do
    procs = HashDict.new
    HashDict.put(procs, :acceptor, Paxos.Acceptor.start_link(instance))
    HashDict.put(procs, :proposer, Paxos.Proposer.start_link(instance, value, false, 1, []))
    insert_instance(instance, procs)
    procs
  end

  defp insert_instance(instance, procs) do
    :ets.insert(:instances, {instance, procs, nil})
  end

  defp get_instance(instance) do
    case :ets.lookup(:instances, instance) do
      {^instance, dict, _ } ->
        dict
      _ ->
        nil
    end
  end

  defp get_next do
    {int, _, _} = :ets.last(:instances)
    int + 1
  end

end
