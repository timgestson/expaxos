defmodule Paxos.Queue do
  
  def new do
    []
  end

  def insert(queue, value) do
    List.insert_at(queue, length(queue), value)
  end

  def take([head | rest]) do
    {:value, head, rest}
  end  
  
  def take([]) do
    :empty
  end

  def is_empty([]) do
    true
  end

  def is_empty(_) do
    false
  end
  
end
