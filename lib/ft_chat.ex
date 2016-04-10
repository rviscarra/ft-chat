defmodule FtChat do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(__MODULE__, [], function: :start_webserver)
    ]

    opts = [strategy: :one_for_one, name: FtChat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start_webserver do
    routes = [
      {"/", :cowboy_static, {:priv_file, :ft_chat, "static/index.html"}},
      {"/chat", FtChat.ChatHandler, []}
    ]

    dispatch = :cowboy_router.compile [{:_, routes}]

    {:ok, _pid} = :cowboy.start_http :http, 100, [port: 8000], [env: [dispatch: dispatch]]
  end

  defmodule ChatHandler do

    def init({:tcp, :http}, req, opts) do
      {:upgrade, :protocol, :cowboy_websocket, req, opts}
    end

    def websocket_init(:tcp, req, _opts) do
      req = :cowboy_req.compact req
      {:ok, req, nil}
    end

    def websocket_handle({:text, text}, req, st) do
      IO.puts "websocket_handle(#{inspect text})"
      {:reply, {:text, text}, req, st}
    end

    def websocket_info(_msg, req, st) do
      {:ok, req, st}
    end

    def websocket_terminate(_reason, _req, _st) do
      :ok
    end
  end
end
