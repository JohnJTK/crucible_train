defmodule CrucibleTrain.Eval.Runner do
  @moduledoc """
  Orchestrates simple evaluations using a message completer.
  """

  require Logger

  alias CrucibleTrain.Completers.MessageCompleter
  alias CrucibleTrain.Renderers.Types

  @type sample :: %{
          required(:id) => String.t(),
          required(:input) => String.t(),
          required(:target) => String.t(),
          optional(:system_prompt) => String.t(),
          optional(atom()) => any()
        }

  @type result :: %{
          required(:id) => String.t(),
          required(:input) => String.t(),
          required(:output) => String.t(),
          required(:target) => String.t(),
          optional(atom()) => any()
        }

  @type scored_result :: %{
          required(:id) => String.t(),
          required(:score) => float(),
          optional(atom()) => any()
        }

  @spec run([sample()], map()) :: {:ok, [result()]} | {:error, term()}
  def run(samples, config) do
    Logger.info("Running evaluation on #{length(samples)} samples...")

    case Map.get(config, :message_completer) do
      nil ->
        {:error, :missing_message_completer}

      completer ->
        total = length(samples)

        results =
          samples
          |> Enum.with_index()
          |> Enum.map(&run_sample_indexed(&1, completer, total))

        Logger.info("Evaluation complete. Processed #{length(results)} samples.")
        {:ok, results}
    end
  end

  defp run_sample_indexed({sample, idx}, completer, total) do
    maybe_log_progress(idx, total)

    case run_sample(sample, completer) do
      {:ok, result} ->
        result

      {:error, reason} ->
        Logger.warning("Sample #{sample.id} failed: #{inspect(reason)}")

        %{
          id: sample.id,
          input: sample.input,
          output: "",
          target: sample.target,
          error: inspect(reason)
        }
    end
  end

  defp maybe_log_progress(idx, total) do
    if rem(idx + 1, 10) == 0 do
      Logger.info("Processing sample #{idx + 1}/#{total}")
    end
  end

  @spec run_sample(sample(), struct()) :: {:ok, result()} | {:error, term()}
  def run_sample(sample, completer) do
    messages = create_messages(sample)

    case MessageCompleter.complete(completer, messages) do
      {:ok, message} ->
        content = Types.ensure_text(message.content)

        result = %{
          id: sample.id,
          input: sample.input,
          output: content,
          target: sample.target
        }

        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec create_messages(sample()) :: [Types.Message.t()]
  def create_messages(sample) do
    messages = []

    messages =
      if sample[:system_prompt] do
        [Types.message("system", sample.system_prompt) | messages]
      else
        messages
      end

    messages ++ [Types.message("user", sample.input)]
  end

  @spec score_results([result()], atom()) :: [scored_result()]
  def score_results(results, method \\ :exact_match) do
    Enum.map(results, fn result ->
      score = compute_score(result.output, result.target, method)
      Map.put(result, :score, score)
    end)
  end

  @spec compute_metrics([scored_result()]) :: map()
  def compute_metrics(scored_results) do
    total = length(scored_results)

    if total == 0 do
      %{accuracy: 0.0, total: 0, correct: 0}
    else
      correct = Enum.count(scored_results, fn r -> r.score == 1.0 end)
      accuracy = correct / total

      %{accuracy: accuracy, total: total, correct: correct}
    end
  end

  defp compute_score(output, target, :exact_match) do
    if String.trim(output) == String.trim(target), do: 1.0, else: 0.0
  end

  defp compute_score(output, target, :contains) do
    if String.contains?(output, target), do: 1.0, else: 0.0
  end

  defp compute_score(output, target, :case_insensitive) do
    if String.downcase(String.trim(output)) == String.downcase(String.trim(target)) do
      1.0
    else
      0.0
    end
  end
end
