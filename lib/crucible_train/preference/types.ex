defmodule CrucibleTrain.Preference.Comparison do
  @moduledoc """
  Comparison between two completions for a shared prompt conversation.
  """

  alias CrucibleTrain.Renderers.Types

  @type t :: %__MODULE__{
          prompt_conversation: [Types.Message.t() | map()],
          completion_a: [Types.Message.t() | map()],
          completion_b: [Types.Message.t() | map()]
        }

  defstruct [:prompt_conversation, :completion_a, :completion_b]

  @spec swap(t()) :: t()
  def swap(%__MODULE__{} = comparison) do
    %__MODULE__{
      comparison
      | completion_a: comparison.completion_b,
        completion_b: comparison.completion_a
    }
  end
end

defmodule CrucibleTrain.Preference.LabeledComparison do
  @moduledoc """
  Comparison with a label indicating the preferred completion.
  """

  alias CrucibleTrain.Preference.Comparison

  @type label :: String.t()

  @type t :: %__MODULE__{
          comparison: Comparison.t(),
          label: label()
        }

  defstruct [:comparison, :label]

  @spec swap(t()) :: t()
  def swap(%__MODULE__{} = labeled) do
    new_label =
      case labeled.label do
        "A" -> "B"
        "B" -> "A"
        "Tie" -> "Tie"
      end

    %__MODULE__{labeled | comparison: Comparison.swap(labeled.comparison), label: new_label}
  end
end

defmodule CrucibleTrain.Preference.ComparisonRenderer do
  @moduledoc """
  Behaviour for rendering comparisons into model inputs.
  """

  alias CrucibleTrain.Preference.{Comparison, LabeledComparison}
  alias CrucibleTrain.Types.ModelInput

  @callback build_generation_prompt(struct(), Comparison.t()) :: ModelInput.t()
  @callback to_model_input_weights(struct(), LabeledComparison.t()) :: {ModelInput.t(), [float()]}
  @callback tokenizer(struct()) :: term()

  @spec build_generation_prompt(struct(), Comparison.t()) :: ModelInput.t()
  def build_generation_prompt(%module{} = renderer, comparison) do
    module.build_generation_prompt(renderer, comparison)
  end

  @spec to_model_input_weights(struct(), LabeledComparison.t()) :: {ModelInput.t(), [float()]}
  def to_model_input_weights(%module{} = renderer, labeled) do
    module.to_model_input_weights(renderer, labeled)
  end

  @spec tokenizer(struct()) :: term()
  def tokenizer(%module{} = renderer) do
    module.tokenizer(renderer)
  end
end

defmodule CrucibleTrain.Preference.ComparisonRendererFromChatRenderer do
  @moduledoc """
  Comparison renderer that adapts an existing chat renderer.
  """

  alias CrucibleTrain.Preference.{Comparison, LabeledComparison}
  alias CrucibleTrain.Renderers.{Renderer, TrainOnWhat, Types}
  alias CrucibleTrain.Types.{EncodedTextChunk, ModelInput}

  defstruct [:renderer_module, :renderer_state]

  @type t :: %__MODULE__{
          renderer_module: module(),
          renderer_state: map()
        }

  @spec build_generation_prompt(t(), Comparison.t()) :: ModelInput.t()
  def build_generation_prompt(%__MODULE__{} = renderer, %Comparison{} = comparison) do
    convo = comparison_to_convo(comparison)

    {model_input, _state} =
      Renderer.build_generation_prompt(
        renderer.renderer_module,
        convo,
        "assistant",
        nil,
        renderer.renderer_state
      )

    model_input
  end

  @spec to_model_input_weights(t(), LabeledComparison.t()) :: {ModelInput.t(), [float()]}
  def to_model_input_weights(%__MODULE__{} = renderer, %LabeledComparison{} = labeled) do
    convo = comparison_to_convo(labeled.comparison)
    convo_with_pref = convo ++ [Types.message("assistant", labeled.label)]

    {model_input, weights} =
      Renderer.build_supervised_example(
        renderer.renderer_module,
        convo_with_pref,
        TrainOnWhat.last_assistant_message(),
        renderer.renderer_state
      )

    if Enum.any?(model_input.chunks, fn chunk -> not match?(%EncodedTextChunk{}, chunk) end) do
      raise ArgumentError, "Preference learning currently only supports text-only content."
    end

    tokens = ModelInput.all_tokens(model_input)

    first_weight_one_index =
      case Enum.find_index(weights, &(&1 == 1.0)) do
        nil -> raise ArgumentError, "No weight==1 token found for preference label"
        idx -> idx
      end

    truncated_tokens = Enum.take(tokens, first_weight_one_index + 1)
    truncated_weights = Enum.take(weights, first_weight_one_index + 1)

    {ModelInput.from_ints(truncated_tokens), truncated_weights}
  end

  @spec tokenizer(t()) :: term()
  def tokenizer(%__MODULE__{} = renderer) do
    Map.fetch!(renderer.renderer_state, :tokenizer)
  end

  defp comparison_to_convo(%Comparison{} = comparison) do
    [
      comparison.prompt_conversation,
      [Types.message("system", "==== Completion A ====")],
      comparison.completion_a,
      [Types.message("system", "==== Completion B ====")],
      comparison.completion_b,
      [Types.message("system", "==== Preference ====")]
    ]
    |> List.flatten()
  end
end
