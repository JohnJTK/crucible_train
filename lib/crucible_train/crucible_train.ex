defmodule CrucibleTrain do
  @moduledoc """
  Unified training infrastructure for ML workloads on the BEAM.
  """

  @doc "Returns a renderer module for the given model name."
  @spec get_renderer(String.t()) :: {:ok, module()} | {:error, term()}
  defdelegate get_renderer(name), to: CrucibleTrain.Renderers.Registry

  @doc "Lists supported renderer names."
  @spec list_renderers() :: [String.t()]
  defdelegate list_renderers(), to: CrucibleTrain.Renderers.Registry

  @doc "Runs supervised training with the given config."
  @spec train_supervised(CrucibleTrain.Supervised.Config.t()) :: {:ok, map()} | {:error, term()}
  defdelegate train_supervised(config), to: CrucibleTrain.Supervised.Train, as: :main

  @doc "Runs reinforcement learning training with the given config."
  @spec train_rl(map()) :: {:ok, map()} | {:error, term()}
  defdelegate train_rl(config), to: CrucibleTrain.RL.Train, as: :main

  @doc "Runs DPO training with the given config."
  @spec train_dpo(map()) :: {:ok, map()} | {:error, term()}
  defdelegate train_dpo(config), to: CrucibleTrain.Preference.TrainDPO, as: :main

  @doc "Creates a logger based on the given type and options."
  @spec create_logger(atom(), keyword()) :: {:ok, term()} | {:error, term()}
  defdelegate create_logger(type, opts), to: CrucibleTrain.Logging

  @doc "Creates a port composition root from options."
  @spec new_ports(keyword()) :: CrucibleTrain.Ports.t()
  defdelegate new_ports(opts), to: CrucibleTrain.Ports, as: :new
end
