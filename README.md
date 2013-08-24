# Paxos

A Multi-Paxos with Master Lease implementation in Elixir
--------------------------------------------------------

iex --sname {nodename} --cookie {cookie} -S mix

#Api

Paxos.start(NodeList)
---------------------
	
Starts Paxos node
	
Paxos.submit(command)
---------------------

Submits a command

Paxos.status()
--------------

Returns status: [:leader, :follower, :candidate, :stragler]

# Todo

Write Test Suite

Catch up stragling Nodes

Persistent Log

