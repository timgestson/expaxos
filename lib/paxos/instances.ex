defmodule Paxos.Instances do
  use GenServer.Behaviour  

  def start_link do 
    :ets.new(:instances, [:set, :named_table, :public, {:keypos, 1}])
  end

  def new_instance do
    :ok
  end

  def message(instance, message) do
    case :ets.lookup(:instances, instance) do
      [{^instance, apid, ppid, value}] when is_pid(ppid) ->
        :gen_server.cast(apid, message)
        :ok
      [{^instance, nil, value}]->
        :instance_closed
      _ ->
        apid = Paxos.Accepter.start_link(instance)
        :ets.insert_new(:instances, {instance, apid, nil, nil})
        :gen_server.cast(apid, message)
        :ok
    end
  end

  def submit(instance, value) do
    :ets.update_element(:instance, instance, {4, value})
  end

  def close(instance) do
    :ets.update_element(:instance, instance, {2, nil})
  end
end
