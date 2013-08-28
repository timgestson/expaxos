
Multi-Paxos with Master Lease in Elixir
---------------------------------------

`iex --sname {nodename} --cookie {cookie} -S mix`

#Api

####`Paxos.start(NodeList, Logname)`
	
Starts Paxos node
	
####`Paxos.submit(command)`

Submits a command

####`Paxos.status()`

Returns status: `[:leader, :follower, :candidate, :stragler]`

####`Paxos.read()`
####`Paxos.read(number_of_entries)`
####`Paxos.read(continuation, number_of_entries)`

Returns `{contiuation, entries}`

Read log entries

returns `{continuation, list}`

####`Paxos.add_handler(module, args)`

add a `gen_event` module 

listen for the `{:log_entry, command, instance}`

## Todo

More Tests

Dynamic Configuration
