defmodule CrucibleTrain.MixProject do
  use Mix.Project

  @version "0.2.0"
  @source_url "https://github.com/North-Shore-AI/crucible_train"

  def project do
    [
      app: :crucible_train,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:ex_unit, :mix],
        flags: [:error_handling, :unknown]
      ],
      name: "CrucibleTrain",
      description: "Unified ML training infrastructure for Elixir/BEAM",
      source_url: @source_url,
      docs: docs(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {CrucibleTrain.Application, []}
    ]
  end

  defp deps do
    [
      {:chz_ex, "~> 0.1.2"},
      {:jason, "~> 1.4"},
      {:req, "~> 0.5"},
      {:telemetry, "~> 1.3"},
      {:table_rex, "~> 4.0"},
      {:ecto_sql, "~> 3.11"},
      {:crucible_framework, "~> 0.5.2"},
      {:crucible_ir, "~> 0.2.1"},
      {:mox, "~> 1.1", only: :test},
      {:stream_data, "~> 1.0", only: [:dev, :test]},
      {:excoveralls, "~> 0.18", only: :test},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      quality: ["format", "credo --strict", "dialyzer"],
      test: ["test --cover"]
    ]
  end

  defp docs do
    [
      main: "readme",
      name: "CrucibleTrain",
      source_ref: "v#{@version}",
      source_url: @source_url,
      homepage_url: @source_url,
      extras: [
        "README.md",
        "CHANGELOG.md",
        "LICENSE",
        {"examples/README.md", [title: "Examples", filename: "examples"]}
      ],
      assets: %{"assets" => "assets"},
      logo: "assets/crucible_train.svg",
      groups_for_modules: [
        Types: [
          CrucibleTrain.Types.Datum,
          CrucibleTrain.Types.ModelInput,
          CrucibleTrain.Types.TensorData,
          CrucibleTrain.Types.TokensWithLogprobs
        ],
        Renderers: [
          CrucibleTrain.Renderers.Renderer,
          CrucibleTrain.Renderers.Types,
          CrucibleTrain.Renderers.TrainOnWhat,
          CrucibleTrain.Renderers.Registry
        ],
        "Supervised Learning": [
          CrucibleTrain.Supervised.Train,
          CrucibleTrain.Supervised.Dataset,
          CrucibleTrain.Supervised.Config
        ],
        "Reinforcement Learning": [
          CrucibleTrain.RL.Train,
          CrucibleTrain.RL.Env,
          CrucibleTrain.RL.EnvGroupBuilder
        ],
        Ports: ~r/CrucibleTrain\.Ports\..*/,
        Logging: ~r/CrucibleTrain\.Logging\..*/
      ]
    ]
  end

  defp package do
    [
      name: "crucible_train",
      description: "Unified ML training infrastructure for Elixir/BEAM",
      files: ~w(README.md CHANGELOG.md mix.exs LICENSE lib assets examples/README.md),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Online documentation" => "https://hexdocs.pm/crucible_train"
      },
      maintainers: ["nshkrdotcom"]
    ]
  end
end
