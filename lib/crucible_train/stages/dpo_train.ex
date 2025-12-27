defmodule CrucibleTrain.Stages.DPOTrain do
  @moduledoc """
  Crucible Stage for DPO training.
  """

  alias CrucibleTrain.Preference.TrainDPO

  if Code.ensure_loaded?(Crucible.Stage) do
    @behaviour Crucible.Stage
  end

  @impl true
  def describe(_opts) do
    %{
      name: :dpo_train,
      description: "Runs Direct Preference Optimization training using CrucibleTrain.Preference",
      required: [],
      optional: [:beta, :epochs, :batch_size, :learning_rate, :reference_model],
      types: %{
        beta: :float,
        epochs: :integer,
        batch_size: :integer,
        learning_rate: :float,
        reference_model: :string
      }
    }
  end

  @impl true
  def run(context, opts) do
    if Code.ensure_loaded?(Crucible.Context) do
      case TrainDPO.main(opts) do
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
