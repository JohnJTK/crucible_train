defmodule CrucibleTrain.Supervised.DatasetTest do
  use ExUnit.Case, async: true

  alias CrucibleTrain.Supervised.{
    Dataset,
    DatasetFromList,
    DatasetFromSamples,
    DatasetFromSamplesFlatMap
  }

  alias CrucibleTrain.Types.{Datum, ModelInput, TensorData}
  alias CrucibleTrain.Utils.PRNG.PCG64

  defp datum_for(id) do
    model_input = ModelInput.from_ints([id, id + 1])

    Datum.new(model_input, %{
      "weights" => TensorData.from_list([1.0], :float32),
      "target_tokens" => TensorData.from_list([id + 1], :int64)
    })
  end

  test "dataset from list returns batches" do
    data = [datum_for(1), datum_for(3)]
    dataset = DatasetFromList.new(data, 1)

    assert Dataset.length(dataset) == 2
    assert Dataset.get_batch(dataset, 0) == [Enum.at(data, 0)]
    assert Dataset.get_batch(dataset, 1) == [Enum.at(data, 1)]
  end

  test "set_epoch shuffles deterministically" do
    data = [datum_for(1), datum_for(3), datum_for(5)]
    dataset = DatasetFromList.new(data, 1)

    shuffled = Dataset.set_epoch(dataset, 42)
    refute shuffled.shuffled_data == nil
    assert length(shuffled.shuffled_data) == 3
  end

  test "dataset from samples uses pcg64 shuffle when configured" do
    samples = Enum.map(1..5, &%{"id" => &1})

    dataset =
      DatasetFromSamples.new(samples, 2, fn sample -> datum_for(sample["id"]) end,
        shuffle: :pcg64
      )

    shuffled = DatasetFromSamples.set_epoch(dataset, 42)
    state = PCG64.seed(42)
    {expected, _} = PCG64.shuffle(samples, state)

    assert shuffled.shuffled_samples == expected
  end

  test "dataset from samples flatmap uses pcg64 shuffle when configured" do
    samples = Enum.map(1..4, &%{"id" => &1})

    dataset =
      DatasetFromSamplesFlatMap.new(samples, 2, fn sample -> [datum_for(sample["id"])] end,
        shuffle: :pcg64
      )

    shuffled = DatasetFromSamplesFlatMap.set_epoch(dataset, 7)
    state = PCG64.seed(7)
    {expected, _} = PCG64.shuffle(samples, state)

    assert shuffled.shuffled_samples == expected
  end
end
