
Multi-Paxos with Master Lease in Elixir
---------------------------------------

iex --sname {nodename} --cookie {cookie} -S mix

#Api

####`Paxos.start(NodeList, Logname)`
	
Starts Paxos node
	
####`Paxos.submit(command)`

Submits a command

####`Paxos.status()`

Returns status: [:leader, :follower, :candidate, :stragler]

####`Paxos.read()`

Read log entries

returns {continuation, list}


####`Paxos.read(continuation)`

returns files after continuation

####`Paxos.add_handler(module, args)`

add a `gen_event` module 

listen for the `{:log_entry, command, instance}`

## Todo

Test Suite

Dynamic Configuration
