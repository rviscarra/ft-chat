defmodule FtChat.ChatHandler do

  defmodule ChatConnState do
    defstruct [:rooms]

    def empty do
      %ChatConnState { rooms: HashSet.new }
    end

    def add(st, room) do
      %{st | rooms: HashSet.put(st.rooms, room) }
    end

    def del(st, room) do
      %{st | rooms: HashSet.delete(st.rooms, room) }
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
    case try_decode_message text, st do
      {:ok, st} ->
        {:noreply, req, st}
      {:reply, Text} ->
        {:reply, {:text, text}, req, st}
    end
  end

  def websocket_info(_msg, req, st) do
    {:ok, req, st}
  end

  def websocket_terminate(_reason, _req, _st) do
    :ok
  end

  defp try_decode_message msg, st do
    
  end
end
