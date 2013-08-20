defmodule Paxos.Coordinator do
  use Paxos.Log.Behaviour

  alias Paxos.Messages.PrepareReq, as: PrepareReq
  alias Paxos.Messages.PrepareResp, as: PrepareResp
  alias Paxos.Messages.AcceptReq, as: AcceptReq
  alias Paxos.Messages.AcceptResp, as: AcceptResp
  alias Paxos.Messages.LearnReq, as: LearnReq

  defrecord Instance, acceptor: nil, proposer: nil, learner: nil, value: nil


  def init do
    :ets.new(:instances, [:ordered_set, :named_table, :public, {:keypos, 1}])
    :ets.insert(:instances, {0,0,0})
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

  def commit(instance, value) do
    inst = get_instance(instance)
    inst = inst.update(value: value)
    insert_instance(instance, inst)
  end

  def get_last_committed(instance) do
    case get_instance(instance - 1) do
      Instance[value: value] when value !== nil ->
        instance - 1        
      _ ->
        get_last_committed(instance - 1)
    end
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
    IO.puts(message.instance)
    IO.puts(inspect(:ets.tab2list(:instances)))
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

  defp get_next do
    int = :ets.last(:instances)
    int + 1
  end

end
