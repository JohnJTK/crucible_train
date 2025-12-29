defmodule CrucibleTrain.Completers.TinkexTokenCompleter do
  @moduledoc """
  Token completer backed by a Tinkex-style sampling client.
  """

  @behaviour CrucibleTrain.Completers.TokenCompleter

  alias CrucibleTrain.Types.TokensWithLogprobs

  defstruct [:sampling_client, :max_tokens, temperature: 1.0]

  @type t :: %__MODULE__{
          sampling_client: struct(),
          max_tokens: pos_integer(),
          temperature: float()
        }

  @spec new(keyword()) :: t()
  def new(opts) do
    struct!(__MODULE__, opts)
  end

  @impl true
  def complete(%__MODULE__{} = completer, model_input, stop) do
    sampling_params = %{
      stop: stop,
      max_tokens: completer.max_tokens,
      temperature: completer.temperature
    }

    sampling_client = completer.sampling_client

    with {:ok, task} <-
           sampling_client.__struct__.sample(
             sampling_client,
             model_input,
             sampling_params,
             num_samples: 1
           ),
         {:ok, response} <- Task.await(task, :infinity),
         {:ok, result} <- extract_tokens_with_logprobs(response) do
      {:ok, result}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp extract_tokens_with_logprobs(response) do
    sequences = response.sequences || response[:sequences] || []

    case sequences do
      [sequence | _] -> extract_from_sequence(sequence)
      [] -> {:error, :no_sequences}
    end
  end

  defp extract_from_sequence(sequence) do
    tokens = sequence.tokens || sequence[:tokens]
    logprobs = sequence.logprobs || sequence[:logprobs]
    validate_tokens_and_logprobs(tokens, logprobs)
  end

  defp validate_tokens_and_logprobs(tokens, _logprobs) when not is_list(tokens) do
    {:error, :invalid_tokens}
  end

  defp validate_tokens_and_logprobs(tokens, logprobs) when is_list(logprobs) do
    {:ok, %TokensWithLogprobs{tokens: tokens, maybe_logprobs: logprobs}}
  end

  defp validate_tokens_and_logprobs(_tokens, _logprobs) do
    {:error, :logprobs_missing}
  end
end
