defmodule Paxos.Transport do
  use GenServer.Behaviour

  defrecord State, ip: {127,0,0,1}, iplist: [], socket: nil, port: 0

  def start_link(port, iplist) do
    :gen_server.start_link({:local, __MODULE__},__MODULE__, [port, iplist], [])
  end

  def send(payload) do
    :gen_server.call(__MODULE__, {:send, payload})
  end

  def broadcast(payload) do
    :gen_server.cast(__MODULE__, {:broadcast, payload})
  end

  def get_nodes do
    :gen_server.call(__MODULE__, :get_nodes)
  end

  def get_self do
    :gen_server.call(__MODULE__, :get_self)
  end

  def init([port, iplist]) do
    {:ok, sock} = :gen_udp.open(port)
    pid = spawn_link(__MODULE__, :recieve_loop, [])
    :gen_udp.controlling_process(sock, pid)
    {:ok, State.new(iplist: iplist, socket: sock, port: port)}
  end

  def handle_call(:get_nodes, _from, state) do
    {:reply, length(state.iplist) + 1, state}
  end

  def handle_call(:get_self, _from, state) do
    {:reply, state.ip, state}
  end
  
  def handle_call({:send, message}, _from, state) do
    :gen_udp.send(state.socket, state.ip, state.port, message)
    {:reply, :ok, state}
  end

  def handle_cast({:broadcast, message}, state) do
    Enum.each(state.iplist, fn({ip, port}) ->
      :gen_udp.send(state.socket, ip, port, message)
    end)
    {:noreply, state}
  end

  def handle_cast({:udp, message}, state) do
    IO.puts(message)
    spawn(__MODULE__, :worker, message)
    {:noreply, state}
  end

  def recieve_loop do
    Stream.repeatedly(fn()->
      receive do
        {:udp, _socket, _ip, _port, data} ->
          {:udp, data}
        _->
          :err
      end
    end) |> Enum.each(:gen_server.cast(__MODULE__, &1))
  end

  def worker(message = Paxos.Messages.PrepareReq[instance: instance]) do
        
  end

  def worker(message = Paxos.Messages.PrepareResp[instance: instance]) do

  end

  def worker(message = Paxos.Messages.AcceptReq[instance: instance]) do

  end

  def worker(message = Paxos.Messages.AcceptResp[instance: instance]) do

  end

  def worker(_) do

  end
end
