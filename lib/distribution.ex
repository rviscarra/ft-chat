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

      def handle_cast({:remote_message, room, message, level}, st) do
        FtChat.ChatRoom.handle_message room, message, level
        {:noreply, st}
      end

    end

    defmodule RemoteChatRoomClient do
      use GenServer
      alias FtChat.ChatRoom, as: ChatRoom

      @process_name __MODULE__

      def start_link do
        GenServer.start_link __MODULE__, nil, name: @process_name
      end

      def cast(room, message) do
        GenServer.cast @process_name, {:remote_cast, room, message}
      end

      def init(_) do
        nodes = Application.get_env(:ft_chat, :nodes, [])
        ring = NodeRing.new nodes, 2
        {:ok, ring}
      end

      defp broadcast_message(nodes, active_nodes, room, message, level) do
        case nodes do
          [] -> :ok
          [target_node | rest] ->
            level =
              if target_node == node() do
                ChatRoom.handle_message room, message, level
                IO.puts "Local: #{inspect message}(#{level})"
                :slave
              else if HashSet.member? active_nodes, target_node do
                  IO.puts "#{node} => #{inspect message} => #{target_node}(#{level})"
                  GenServer.abcast([target_node], FtChat.Distribution.RemoteChatRoomServer, {:remote_message, room, message, level})
                  :slave
                else
                  level
                end
              end
            broadcast_message rest, active_nodes, room, message, level
        end
      end

      def handle_cast({:remote_cast, room, message}, ring) do
        alive_nodes =
          Node.list(:connected)
          |> List.foldl(HashSet.new, &HashSet.put(&2, &1))
        nodes = NodeRing.get_nodes_for(ring, room)
        IO.puts "Alive = #{inspect alive_nodes}. Nodes = #{inspect nodes}"
        broadcast_message nodes, alive_nodes, room, message, :master
        {:noreply, ring}
      end

    end

end
