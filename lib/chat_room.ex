defmodule FtChat.ChatRoom do

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
