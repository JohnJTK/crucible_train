defmodule CrucibleTrain.Stages.RLTrain do
  @moduledoc """
  Crucible Stage for reinforcement learning.
  """

  alias CrucibleTrain.RL.Train

  if Code.ensure_loaded?(Crucible.Stage) do
    @behaviour Crucible.Stage
  end

  @impl true
  def describe(_opts) do
    %{
      name: :rl_train,
      description: "Runs reinforcement learning training using CrucibleTrain.RL",
      required: [],
      optional: [:algorithm, :gamma, :epsilon, :learning_rate, :episodes, :reward_fn],
      types: %{
        algorithm: {:enum, [:ppo, :dqn, :a2c, :reinforce]},
        gamma: :float,
        epsilon: :float,
        learning_rate: :float,
        episodes: :integer,
        reward_fn: {:function, 1}
      }
    }
  end

  @impl true
  def run(context, opts) do
    if Code.ensure_loaded?(Crucible.Context) do
      case Train.main(opts) do
        {:ok, result} ->
          context = merge_metrics(context, result[:metrics] || %{})
          {:ok, context}

        {:error, reason} ->
          {:error, reason}
      end
    else
      {:error, :crucible_framework_not_available}
    end
  end

  if Code.ensure_loaded?(Crucible.Context) and
       function_exported?(Crucible.Context, :merge_metrics, 2) do
    defp merge_metrics(context, metrics) when is_map(metrics) do
      Crucible.Context.merge_metrics(context, metrics)
    end
  else
    defp merge_metrics(context, metrics) when is_map(metrics) do
      updated = Map.merge(Map.get(context, :metrics, %{}), metrics)
      Map.put(context, :metrics, updated)
    end
  end
end
