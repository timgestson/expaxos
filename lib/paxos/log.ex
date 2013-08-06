defmodule Paxos.Log do
  use Behaviour
  
  defcallback init

  defcallback message(message :: Record)

  defcallback submit(value :: Term)

end

defmodule Paxos.Log.Behaviour do
  defmacro __using__(_) do
    quote location: :keep do
        @behaviour Paxos.Log

    end
  end
end
