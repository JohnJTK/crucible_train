defmodule CrucibleTrain.Supervised.CommonTest do
  use ExUnit.Case, async: true

  alias CrucibleTrain.Supervised.Common
  alias CrucibleTrain.Types.{EncodedTextChunk, ModelInput}

  test "datum_from_model_input_weights builds shifted targets" do
    chunks = [%EncodedTextChunk{tokens: [1, 2, 3]}]
    model_input = %ModelInput{chunks: chunks}
    weights = [0.0, 1.0, 1.0]

    datum = Common.datum_from_model_input_weights(model_input, weights, nil)

    assert datum.loss_fn_inputs["target_tokens"].data == [2, 3]
    assert datum.loss_fn_inputs["weights"].data == [1.0, 1.0]
  end
end
