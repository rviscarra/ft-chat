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
      defstruct [:name, :users]
  end

  use GenServer

  def start_link(name) do
      GenServer.start_link __MODULE__, name
  end

  def join(chat_room, user) do
      GenServer.cast chat_room, {:join, user}
  end

  def leave(chat_room, user) do
      GenServer.cast chat_room, {:leave, user}
  end

  def post(chat_room, message) do
      GenServer.cast chat_room, {:post, message}
  end

  def init(name) do
      {:ok, %ChatRoomState{
          name: name,
          users: HashSet.new
      }}
  end

  def handle_cast({:join, user}, st) do
      st = %{ st | users: HashSet.put(st.users, user) }
      {:noreply, st}
  end

  def handle_cast({:leave, user}, st) do
      st = %{ st | users: HashSet.delete(st.users, user) }
      {:noreply, st}
  end

  def handle_cast({:post, message}, st) do
      Enum.each st.users &(send &1, {:chat_message, st.name, message})
      {:noreply, st}
  end
end
