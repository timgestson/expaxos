defmodule Paxos.Coordinator do

  alias Paxos.Messages.PrepareReq, as: PrepareReq
  alias Paxos.Messages.PrepareResp, as: PrepareResp
  alias Paxos.Messages.AcceptReq, as: AcceptReq
  alias Paxos.Messages.AcceptResp, as: AcceptResp
  alias Paxos.Messages.LearnReq, as: LearnReq

  defrecord Instance, acceptor: nil, proposer: nil, closed: false

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
    instance = Paxos.Logger.get_instance
    start_instance(instance, value)
  end

  def close_instance(instance) do
    inst = get_instance(instance)
    inst = inst.update(closed: true)
    insert_instance(instance, inst)
  end

  defp message_acceptor(message) do
    case get_instance(message.instance) do
      nil ->
        procs = start_instance(message.instance)
        Paxos.Acceptor.message(procs.acceptor, message) 
      procs ->
        Paxos.Acceptor.message(procs.acceptor, message)
    end
    :ok
  end

  defp message_proposer(message) do
    procs =  get_instance(message.instance)
    pid = procs.proposer
    Paxos.Proposer.message(pid, message)
    :ok
  end

  defp start_instance(instance) do
    procs = Instance.new
    {:ok, pid} = Paxos.Acceptor.start_link(instance)
    procs = procs.update(acceptor: pid)
    insert_instance(instance, procs) 
    procs
  end

  defp start_instance(instance, value) do
    procs = Instance.new
    {:ok, apid} =  Paxos.Acceptor.start_link(instance)
    {:ok, ppid} = Paxos.Proposer.start_link(instance, value)
    procs = procs.update(acceptor: apid)
    procs = procs.update(proposer: ppid)
    insert_instance(instance, procs)
    procs
  end

  defp insert_instance(instance, procs) do
    :ets.insert(:instances, {instance, procs})
  end

  defp get_instance(instance) do
    case :ets.lookup(:instances, instance) do
      [{^instance, procs}] ->
        procs
      _ ->
       nil
    end
  end

end
