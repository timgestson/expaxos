defmodule Paxos.Events.External do
  
  def start_link() do
    :gen_event.start_link({:local, :external_event})
  end

  def add_handler(handler, args) do
    :gen_event.add_handler(:external_event, handler, args)
  end

  def delete_handle(handler, args) do
    :gen_event.delete_hander(:external_event, handler, args)
  end

  def log(command) do
    :gen_event.sync_notify(:external_event, {:command, command})
  end

  def snapshot(file) do
    :gen_event.sync_notify(:external_event, {:snapshot, file})
  end

  def call(module, command) do
    :gen_event.call(:external_event, module, command)
  end

end
