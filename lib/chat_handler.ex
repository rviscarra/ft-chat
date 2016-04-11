defmodule FtChat.ChatHandler do

  defmodule ChatConnState do
    defstruct [:user, :rooms]

    def empty do
      %ChatConnState { user: nil, rooms: HashSet.new }
    end

    def add_room(st, room) do
      %{st | rooms: HashSet.put(st.rooms, room) }
    end

    def del_room(st, room) do
      %{st | rooms: HashSet.delete(st.rooms, room) }
    end

    def set_user(st, user) do
      %{st | user: user }
    end
  end

  def init({:tcp, :http}, req, opts) do
    {:upgrade, :protocol, :cowboy_websocket, req, opts}
  end

  def websocket_init(:tcp, req, _opts) do
    req = :cowboy_req.compact req
    {:ok, req, ChatConnState.empty}
  end

  def websocket_handle({:text, text}, req, st) do
    case handle_message JSON.decode(text), st do
      {:ok, st} ->
        {:ok, req, st}
      :close ->
        {:stop, :normal, req, st}
    end
  end

  def websocket_info({:chat_message, from_user, room, message}, req, st) do
    {:ok, text} = JSON.encode(%{action: :message, user: from_user, room: room, message: message})
    {:reply, {:text, text}, req, st}
  end

  def websocket_info({:chat_history, room, history}, req, st) do
    history = Enum.map history, (fn {user, message} -> %{user: user, message: message} end)
    {:ok, text} = JSON.encode(%{action: :history, room: room, history: history})
    {:reply, {:text, text}, req, st}
  end

  def websocket_terminate(_reason, _req, st) do
    Enum.each st.rooms, (fn room ->
      FtChat.ChatRoom.leave room, st.user
    end)
  end

  defp handle_message {:ok, json_message}, st do
    case json_message do
      %{ "action" => "login", "user" => user } ->
        {:ok, ChatConnState.set_user(st, user)}
      %{ "action" => "join",  "room" => room } ->
        FtChat.ChatRoom.join room, st.user
        {:ok, ChatConnState.add_room(st, room)}
      %{ "action" => "leave", "room" => room } ->
        FtChat.ChatRoom.leave room, st.user
        {:ok, ChatConnState.del_room(st, room)}
      %{ "action" => "post", "room" => room, "message" => message} ->
        FtChat.ChatRoom.post room, st.user, message
        {:ok, st}
      _ ->
        :close
    end
  end

  defp handle_message msg, st do
    IO.puts "Closing connection. Message = #{inspect msg}, State = #{inspect st}"
    :close
  end
end
