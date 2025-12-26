defmodule CrucibleTrain.Types do
  @moduledoc """
  Core types for CrucibleTrain.
  """

  alias CrucibleTrain.Types.{
    Datum,
    EncodedTextChunk,
    ImageChunk,
    ModelInput,
    TensorData,
    TokensWithLogprobs
  }

  @type tensor_data :: TensorData.t()
  @type model_input :: ModelInput.t()
  @type encoded_text_chunk :: EncodedTextChunk.t()
  @type image_chunk :: ImageChunk.t()
  @type datum :: Datum.t()
  @type tokens_with_logprobs :: TokensWithLogprobs.t()
end
