
Multi-Paxos with Master Lease in Elixir
---------------------------------------

iex --sname {nodename} --cookie {cookie} -S mix

#Api

Paxos.start(NodeList, Logname)
---------------------
	
Starts Paxos node
	
Paxos.submit(command)
---------------------

Submits a command

Paxos.status()
--------------

Returns status: [:leader, :follower, :candidate, :stragler]

Paxos.read()
------------

Read log entries

# Todo

Catch up for straglers

Test Suite
