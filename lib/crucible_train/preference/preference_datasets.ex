defmodule CrucibleTrain.Preference.ComparisonDatasetBuilder do
  @moduledoc """
  Behaviour for building datasets of labeled comparisons.
  """

  alias CrucibleTrain.Preference.LabeledComparison

  @callback get_train_and_test_datasets(struct()) :: {list(map()), list(map()) | nil}
  @callback example_to_labeled_comparison(struct(), map()) :: LabeledComparison.t() | nil

  @spec get_train_and_test_datasets(struct()) :: {list(map()), list(map()) | nil}
  def get_train_and_test_datasets(%module{} = builder) do
    {train, test} = module.get_train_and_test_datasets(builder)
    {dataset_to_list(train), dataset_to_list(test)}
  end

  @spec example_to_labeled_comparison(struct(), map()) :: LabeledComparison.t() | nil
  def example_to_labeled_comparison(%module{} = builder, example) do
    module.example_to_labeled_comparison(builder, example)
  end

  @spec get_labeled_comparisons(struct()) ::
          {[LabeledComparison.t()], [LabeledComparison.t()] | nil}
  def get_labeled_comparisons(builder) do
    {train_dataset, test_dataset} = get_train_and_test_datasets(builder)

    train = process_labeled_comparisons(builder, train_dataset)
    test = if test_dataset, do: process_labeled_comparisons(builder, test_dataset), else: nil

    {train, test}
  end

  defp process_labeled_comparisons(builder, dataset) do
    Enum.reduce(dataset, [], fn example, acc ->
      case example_to_labeled_comparison(builder, example) do
        nil -> acc
        labeled -> [labeled | acc]
      end
    end)
    |> Enum.reverse()
  end

  defp dataset_to_list(nil), do: nil
  defp dataset_to_list(list) when is_list(list), do: list
  defp dataset_to_list(%{items: items}) when is_list(items), do: items
  defp dataset_to_list(dataset), do: dataset
end

defmodule CrucibleTrain.Preference.ChatDatasetBuilderFromComparisons do
  @moduledoc """
  Chat dataset builder that derives datums from labeled comparisons.
  """

  alias CrucibleTrain.Preference.{
    ComparisonDatasetBuilder,
    ComparisonRendererFromChatRenderer,
    LabeledComparison
  }

  alias CrucibleTrain.Supervised.{Common, DatasetFromSamplesFlatMap}

  defstruct [
    :comparison_builder,
    :renderer_module,
    :renderer_state,
    :batch_size,
    :max_length,
    swap: false
  ]

  @spec build(struct()) :: {DatasetFromSamplesFlatMap.t(), DatasetFromSamplesFlatMap.t() | nil}
  def build(%__MODULE__{} = builder) do
    comparison_renderer = %ComparisonRendererFromChatRenderer{
      renderer_module: builder.renderer_module,
      renderer_state: builder.renderer_state
    }

    {train_dataset, test_dataset} =
      ComparisonDatasetBuilder.get_train_and_test_datasets(builder.comparison_builder)

    comparison_to_datum = fn %LabeledComparison{} = labeled ->
      {model_input, weights} =
        ComparisonRendererFromChatRenderer.to_model_input_weights(comparison_renderer, labeled)

      Common.datum_from_model_input_weights(model_input, weights, builder.max_length)
    end

    example_to_data = fn example ->
      labeled =
        ComparisonDatasetBuilder.example_to_labeled_comparison(
          builder.comparison_builder,
          example
        )

      cond do
        labeled == nil ->
          []

        builder.swap ->
          [comparison_to_datum.(labeled), comparison_to_datum.(LabeledComparison.swap(labeled))]

        random_swap?(example) ->
          [comparison_to_datum.(LabeledComparison.swap(labeled))]

        true ->
          [comparison_to_datum.(labeled)]
      end
    end

    train =
      DatasetFromSamplesFlatMap.new(
        train_dataset,
        builder.batch_size,
        example_to_data
      )

    test =
      if test_dataset != nil do
        DatasetFromSamplesFlatMap.new(
          test_dataset,
          length(test_dataset),
          example_to_data
        )
      else
        nil
      end

    {train, test}
  end

  defp random_swap?(example) do
    rem(:erlang.phash2(example), 2) == 0
  end
end

defmodule CrucibleTrain.Preference.ComparisonBuilderFromJsonl do
  @moduledoc """
  Load labeled comparisons from JSONL files.
  """

  alias CrucibleTrain.Preference.{Comparison, LabeledComparison}

  defstruct [:train_path, :test_path]

  @spec get_train_and_test_datasets(struct()) :: {list(map()), list(map()) | nil}
  def get_train_and_test_datasets(%__MODULE__{} = builder) do
    train = load_jsonl(builder.train_path)
    test = if builder.test_path, do: load_jsonl(builder.test_path), else: nil
    {train, test}
  end

  @spec example_to_labeled_comparison(struct(), map()) :: LabeledComparison.t() | nil
  def example_to_labeled_comparison(%__MODULE__{}, example) when is_map(example) do
    case example do
      %{"comparison" => comparison_map, "label" => label} ->
        %LabeledComparison{
          comparison: %Comparison{
            prompt_conversation: Map.get(comparison_map, "prompt_conversation", []),
            completion_a: Map.get(comparison_map, "completion_A", []),
            completion_b: Map.get(comparison_map, "completion_B", [])
          },
          label: label
        }

      _ ->
        nil
    end
  end

  defp load_jsonl(path) do
    path
    |> Path.expand()
    |> File.stream!()
    |> Enum.reduce([], fn line, acc ->
      case String.trim(line) do
        "" -> acc
        trimmed -> [Jason.decode!(trimmed) | acc]
      end
    end)
    |> Enum.reverse()
  end
end
