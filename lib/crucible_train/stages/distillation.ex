defmodule CrucibleTrain.Stages.Distillation do
  @moduledoc """
  Crucible Stage for distillation training.
  """

  alias CrucibleTrain.Distillation.TrainOnPolicy

  if Code.ensure_loaded?(Crucible.Stage) do
    @behaviour Crucible.Stage
  end

  @impl true
  def describe(_opts) do
    %{
      name: :distillation,
      description: "Runs knowledge distillation training using CrucibleTrain.Distillation",
      required: [],
      optional: [:teacher_model, :student_model, :temperature, :alpha, :epochs],
      types: %{
        teacher_model: :string,
        student_model: :string,
        temperature: :float,
        alpha: :float,
        epochs: :integer
      }
    }
  end

  @impl true
  def run(context, opts) do
    if Code.ensure_loaded?(Crucible.Context) do
      case TrainOnPolicy.main(opts) do
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
