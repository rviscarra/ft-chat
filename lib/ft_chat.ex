defmodule FtChat do
  use Application
  require Logger

  def try_connect(nodes) do
    Enum.each nodes, &Node.ping/1
    receive do
      _ -> :ok
    after 1000 ->
      alive = Node.list :connected
      # IO.puts "#{node} => #{inspect alive}"
      try_connect nodes
    end
  end

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(__MODULE__, [], function: :start_webserver),
      worker(FtChat.ChatRoom.Manager, []),
      worker(FtChat.Distribution.RemoteChatRoomClient, []),
      worker(FtChat.Distribution.RemoteChatRoomServer, [])
    ]

    opts = [strategy: :one_for_one, name: FtChat.Supervisor]
    supervision = Supervisor.start_link children, opts

    nodes = Application.get_env :ft_chat, :nodes, []
    spawn(fn -> try_connect nodes end)

    rooms = Application.get_env :ft_chat, :rooms, []
    Enum.each rooms, &FtChat.ChatRoom.Manager.create_room/1

    supervision
  end

  def start_webserver do
    routes = [
      {"/", :cowboy_static, {:priv_file, :ft_chat, "static/index.html"}},
      {"/assets/[...]", :cowboy_static, {:priv_dir, :ft_chat, "static/"}},
      {"/rooms", FtChat.RoomHandler, []},
      {"/chat", FtChat.ChatHandler, []}
    ]

    dispatch = :cowboy_router.compile [{:_, routes}]

    port = Application.get_env :ft_chat, :port, 8000

    Logger.info "Starting WebSocket server on *:#{port}"

    {:ok, _pid} = :cowboy.start_http :http, 100, [port: port], [env: [dispatch: dispatch]]
  end

end
