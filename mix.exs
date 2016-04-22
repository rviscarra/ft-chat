defmodule FtChat.Mixfile do
  use Mix.Project

  def project do
    [app: :ft_chat,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :cowboy, :uuid],
     mod: {FtChat, []},
     env: [
       rooms: ["Alpha", "Beta", "Gamma"],
       nodes: [
         :node1@localhost,
         :node2@localhost,
         :node3@localhost
       ]
     ]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
        {:cowboy, "~> 1.0"},
        {:json, "~> 0.3.0"},
        {:uuid, "~> 1.1.3"}
    ]
  end
end

defmodule Mix.Tasks.RunNode do
  use Mix.Task

  def run([]) do
    Mix.shell.error "Expected --port PORT"
  end

  def run(args) do
    {opts, _, _} = OptionParser.parse args, strict: [port: :integer]

    Application.put_env(:ft_chat, :port, opts[:port])
    Mix.Task.run("compile", [])
    Mix.Task.run("run", args)
  end

end

defmodule Mix.Tasks.Assets do
  use Mix.Task

  def run(_) do
    local_path = "node_modules/coffee-script/bin/coffee"
    coffee_bin =
      cond do
        File.exists? local_path ->
          local_path
        Mix.shell.cmd "which coffee" == 0 ->
          "coffee"
        true ->
          nil
      end

    if coffee_bin == nil do
      Mix.shell.error "Can't find coffee binary"
    else
      Mix.shell.info "Using coffee from #{coffee_bin}"
    end
  end
end
