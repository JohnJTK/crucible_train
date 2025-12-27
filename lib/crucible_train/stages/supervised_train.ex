defmodule CrucibleTrain.Stages.SupervisedTrain do
  @moduledoc """
  Crucible Stage for supervised learning.
  """

  alias CrucibleTrain.Supervised.{Config, Train}

  if Code.ensure_loaded?(Crucible.Stage) do
    @behaviour Crucible.Stage
  end

  @impl true
  def describe(_opts) do
    %{
      name: :supervised_train,
      description: "Runs supervised learning training using CrucibleTrain.Supervised",
      required: [],
      optional: [:epochs, :batch_size, :learning_rate, :optimizer, :loss_fn, :metrics],
      types: %{
        epochs: :integer,
        batch_size: :integer,
        learning_rate: :float,
        optimizer: :atom,
        loss_fn: :atom,
        metrics: {:list, :atom}
      }
    }
  end

  @impl true
  def run(context, opts) do
    if Code.ensure_loaded?(Crucible.Context) do
      config = build_config(opts, context)

      case Train.main(config) do
        {:ok, result} ->
          context = merge_metrics(context, result[:final_metrics] || %{})

          {:ok, context}

        {:error, reason} ->
          {:error, reason}
      end
    else
      {:error, :crucible_framework_not_available}
    end
  end

  defp build_config(opts, _context) do
    %Config{}
    |> struct!(opts)
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
