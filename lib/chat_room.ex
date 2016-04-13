defmodule FtChat.ChatRoom do

  defmodule Manager do
    use GenServer
    alias FtChat.ChatRoom, as: ChatRoom

    @table_name :chat_room_index
    @process_name __MODULE__

    def start_link() do
      GenServer.start_link(__MODULE__, nil, name: @process_name)
    end

    def get_room(room_name) do
      case :ets.lookup(@table_name, room_name) do
        [{^room_name, pid}] ->
          {:ok, pid}
        _ ->
          :undefined
      end
    end

    def create_room(room_name) do
      GenServer.call @process_name, {:create_room, room_name}
    end

    def init(_args) do
      @table_name = :ets.new(@table_name, [:set, :protected, :named_table, read_concurrency: true])
      {:ok, nil}
    end

    def handle_call({:create_room, room_name}, _from, st) do
      case :ets.lookup(@table_name, room_name) do
        [] ->
          {:ok, pid} = ChatRoom.start_link(room_name)
          :ets.insert(@table_name, {room_name, pid})
          :ok
        [_] ->
          :ok
      end
      {:reply, :ok, st}
    end

  end

  defmodule ChatRoomState do
      defstruct [:name, :users, :history]
  end

  use GenServer
  alias FtChat.Distribution.RemoteChatRoomClient, as: RemoteChatRoomClient

  def start_link(name) do
      GenServer.start_link __MODULE__, name
  end

  defp _cast(chat_room, message, level) do
    case Manager.get_room chat_room do
      :undefined ->
        IO.puts "Can't find #{inspect chat_room}"
        :ok
      {:ok, pid} ->
        GenServer.cast pid, {level, message}
    end
  end

  def join(chat_room, user) do
    RemoteChatRoomClient.cast chat_room, {:join, user, self}
  end

  def leave(chat_room, user) do
    RemoteChatRoomClient.cast chat_room, {:leave, user}
  end

  def post(chat_room, from_user, message) do
    RemoteChatRoomClient.cast chat_room, {:post, from_user, message}
  end

  def handle_message(chat_room, message, level) do
    _cast chat_room, message, level
  end

  def init(name) do
    {:ok, %ChatRoomState{
        name: name,
        users: %{},
        history: :queue.new
    }}
  end

  def handle_cast({level, {:join, user, pid}}, st) do
    st = %{ st | users: put_in(st.users, [user], {level, pid}) }
    if level == :master do
      send pid, {:chat_history, st.name, :queue.to_list(st.history)}
    end
    {:noreply, st}
  end

  def handle_cast({_level, {:leave, user}}, st) do
    st = %{ st | users: Map.delete(st.users, user) }
    {:noreply, st}
  end

  def handle_cast({_level, {:post, from_user, message}}, st) do
    Enum.each st.users, (fn {_, {level, pid}} ->
      if level == :master do
        send pid, {:chat_message, from_user, st.name, message}
      end
    end)
    history =
      if :queue.len(st.history) == 30 do
        {_, history} = :queue.out st.history
        history
      else
        st.history
      end
    st = %{ st | history: :queue.in({from_user, message}, history) }
    {:noreply, st}
  end

end
