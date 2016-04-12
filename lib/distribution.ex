defmodule FtChat.Distribution do

    defmodule NodeRing do
        defstruct [:rules, :replication, :partitions]

        def new(nodes, replication, partitions \\ 32) do
            num_nodes = Enum.count nodes
            ring =
              if num_nodes > 0 do
                1..partitions
                |> Enum.map(fn i ->
                    Enum.at nodes, (rem(i - 1, num_nodes))
                end)
              else
                []
              end
            %NodeRing {
                rules: List.to_tuple(ring),
                replication: replication,
                partitions: partitions
            }
        end

        def get_nodes_for(ring, value) do
            hash = :erlang.phash2 value
            lower_index = rem(hash, ring.partitions)
            upper_index = lower_index + ring.replication - 1
            lower_index..upper_index
            |> Enum.map(&(elem ring.rules, rem(&1, ring.partitions)))
        end

    end

    defmodule RemoteChatRoomServer do
      use GenServer

      @process_name __MODULE__

      def start_link do
        GenServer.start_link(__MODULE__, nil, name: @process_name)
      end

      def init(_) do
        {:ok, nil}
      end

      def handle_cast({:remote_message, room, message}, st) do
        FtChat.ChatRoom.remote_message(room, message)
        {:noreply, st}
      end

    end

    defmodule RemoteChatRoomClient do
      use GenServer

      @process_name __MODULE__

      def start_link do
        GenServer.start_link __MODULE__, nil, name: @process_name
      end

      def remote_cast(room, message) do
        GenServer.cast @process_name, {:remote_cast, room, message}
      end

      def init(_) do
        nodes = Application.get_env(:ft_chat, :nodes, [])
        ring = NodeRing.new nodes, 2
        {:ok, ring}
      end

      def handle_cast({:remote_cast, room, message}, ring) do
        nodes =
          NodeRing.get_nodes_for(ring, room)
          |> Enum.filter(&(&1 != node()))
        message = {:remote_message, room, message}
        IO.puts "Replicating message to #{inspect nodes}"
        GenServer.abcast(nodes, FtChat.Distribution.RemoteChatRoomServer, message)
        {:noreply, ring}
      end

    end

end
