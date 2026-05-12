defmodule Mix.Tasks.Demo do
  use Mix.Task

  @shortdoc "Runs the terminal trading engine demo"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _remaining, _invalid} =
      OptionParser.parse(args,
        switches: [nodes: :integer, speed: :float, engine_name: :string],
        aliases: [n: :nodes, s: :speed]
      )

    {:ok, _pid} = TradingEngine.Demo.start_link(opts)

    Mix.shell().info("Demo ativa. Pressione Ctrl+C para sair.")
    Process.sleep(:infinity)
  end
end