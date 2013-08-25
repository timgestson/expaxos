defmodule Paxos.Events do
  use GenEvent.Behaviour

  def start_link do
    :gen_event.start_link({:local, __MODULE__})
  end

  def add_handler(handler, args) do
    :gen_event.add_handler(__MODULE__, handler, args)
  end

  def delete_handle(handler, args) do
    :gen_event.delete_hander(__MODULE__, handler, args)
  end

  def log_entry(command) do
    :gen_event.sync_notify(__MODULE__, {:log_entry, command})
  end

end
