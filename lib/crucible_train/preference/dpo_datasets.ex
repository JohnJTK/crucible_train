defmodule CrucibleTrain.Preference.DPODatasets do
  @moduledoc """
  Helpers for building DPO datasets from labeled comparisons.
  """

  alias CrucibleTrain.Preference.LabeledComparison
  alias CrucibleTrain.Renderers.{Renderer, TrainOnWhat}
  alias CrucibleTrain.Supervised.{Common, DatasetFromSamplesFlatMap}

  @spec from_labeled([LabeledComparison.t()], module(), map(), keyword()) ::
          {DatasetFromSamplesFlatMap.t(), DatasetFromSamplesFlatMap.t() | nil}
  def from_labeled(labeled_comparisons, renderer_module, renderer_state, opts \\ []) do
    max_length = Keyword.get(opts, :max_length)
    batch_size = Keyword.get(opts, :batch_size, 1)

    example_to_data = fn %LabeledComparison{} = labeled ->
      comparison = labeled.comparison

      chosen_completion =
        if labeled.label == "A" do
          comparison.completion_a
        else
          comparison.completion_b
        end

      rejected_completion =
        if labeled.label == "A" do
          comparison.completion_b
        else
          comparison.completion_a
        end

      chosen_convo = comparison.prompt_conversation ++ chosen_completion
      rejected_convo = comparison.prompt_conversation ++ rejected_completion

      {chosen_input, chosen_weights} =
        Renderer.build_supervised_example(
          renderer_module,
          chosen_convo,
          TrainOnWhat.last_assistant_message(),
          renderer_state
        )

      {rejected_input, rejected_weights} =
        Renderer.build_supervised_example(
          renderer_module,
          rejected_convo,
          TrainOnWhat.last_assistant_message(),
          renderer_state
        )

      [
        Common.datum_from_model_input_weights(chosen_input, chosen_weights, max_length),
        Common.datum_from_model_input_weights(rejected_input, rejected_weights, max_length)
      ]
    end

    train = DatasetFromSamplesFlatMap.new(labeled_comparisons, batch_size, example_to_data)
    {train, nil}
  end
end
