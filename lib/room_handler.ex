defmodule FtChat.RoomHandler do
  alias FtChat.ChatRoom.Manager, as: Manager

  def init({:tcp, :http}, req, _opts) do
    {:ok, req, nil}
  end

  def handle(req, state) do
    headers = [
      {"Content-Type", "application/json"}
    ]
    {:ok, response_body} = JSON.encode %{rooms: Manager.all_rooms}
    {:ok, req} = :cowboy_req.reply(200, headers, response_body, req)
    {:ok, req, state}
  end

  def terminate(_reason, _req, _state) do
    :ok
  end

end
