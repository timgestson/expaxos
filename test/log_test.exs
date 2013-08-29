Code.require_file "test_helper.exs", __DIR__

defmodule Paxos.Proposer.Test do
  use ExUnit.Case
  alias Paxos.Logger, as: Log
  alias Paxos.Logger.State, as: State
  alias Paxos.Logger.Entry, as: Entry

  test "assert true" do
    assert true
  end

end
