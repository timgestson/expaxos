defmodule Paxos.Messages do
  defrecord PrepareReq, instance: 0, ballot: 0, nodeid: nil

  defrecord AcceptReq, instance: 0, ballot: 0, nodeid: nil, value: nil

  defrecord PrepareResp, instance: 0, ballot: 0, nodeid: nil, hab: nil, hav: nil

  defrecord AcceptResp, instance: 0, ballot: 0, nodeid: nil

end
