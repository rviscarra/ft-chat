defmodule FtChat.Distribution do

    defmodule NodeRing do
        defstruct [:rules, :replication, :partitions]

        def new(nodes, replication, partitions \\ 32) do
            num_nodes = Enum.count nodes
            ring =
                1..partitions
                |> Enum.map(fn i ->
                    Enum.at nodes, (rem(i - 1, num_nodes))
                end)
            %NodeRing {
                rules: List.to_tuple(ring),
                replication: replication,
                partitions: partitions
            }
        end

        def get_node_for(ring, value) do
            hash = :erlang.phash2 value
            lower_index = rem(hash, ring.partitions)
            upper_index = lower_index + ring.replication - 1
            lower_index..upper_index
            |> Enum.map(&(elem ring.rules, rem(&1, ring.partitions)))
        end

    end

end
