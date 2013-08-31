
Multi-Paxos with Master Lease in Elixir
---------------------------------------

`iex --sname {nodename} --cookie {cookie} -S mix`

#Api

####`Paxos.start(NodeList, Logname)`
	
Starts Paxos node
	
####`Paxos.call(command)`

Submits a command and blocks until its committed

####`Paxos.cast(command)`

Submits a command and returns immediatly

####`Paxos.status()`

Returns status: `[:leader, :follower, :candidate, :stragler]`

####`Paxos.read()`
####`Paxos.read(number_of_entries)`
####`Paxos.read(continuation, number_of_entries)`

Returns `{contiuation, entries}`

Read log entries

####`Paxos.add_handler(module, args)`

Add a `gen_event` module 

Events:
 `{:command, command}`
 `{:snapshot, file}`

####`Paxos.playback()`

Playback the log on event at a time
(usually call this at startup to get to the current state)

####`Paxos.snapshot_prepare()`

Returns {file, current instance}
write snapshot to the file then 
call `Paxos.snapshot_submit`

####`Paxos.snapshot_submit(handle)`

Handle is {file,instance} that was returned 
by `Paxos.snapshot_prepare`

## Todo

More Tests

Dynamic Configuration
