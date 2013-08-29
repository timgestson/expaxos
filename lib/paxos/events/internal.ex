defmodule Paxos.Events.Internal do

  def start_link(log) do
    event = :gen_event.start_link({:local, :internal_event})
    Paxos.Logger.start_link(log)
    event
  end

   def add_handler(handler, args) do
    :gen_event.add_handler(:internal_event, handler, args)
  end

  def add_sup_handler(handler, args) do
    :gen_event.add_sup_handler(:internal_event, handler, args)
  end  

  def delete_handle(handler, args) do
    :gen_event.delete_hander(:internal_event, handler, args)
  end

  def log(command, instance) do
    :gen_event.sync_notify(:internal_event, {:log, command, instance})
  end

  def call(module, command) do
    :gen_event.call(:internal_event, module, command)
  end

end
