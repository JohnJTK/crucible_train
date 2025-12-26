defmodule CrucibleTrain.Supervised.NLLEvaluator do
  @moduledoc """
  Evaluator that computes negative log-likelihood on a test dataset.
  """

  @behaviour CrucibleTrain.Eval.Evaluators.TrainingClientEvaluator

  alias CrucibleTrain.Ports.TrainingClient
  alias CrucibleTrain.Supervised.{Common, Dataset}
  alias CrucibleTrain.Types.{Datum, TensorData}

  defstruct [:data, :name]

  @type t :: %__MODULE__{
          data: [Datum.t()],
          name: String.t()
        }

  @doc """
  Creates a new NLLEvaluator from a list of datums.
  """
  @spec new([Datum.t()], keyword()) :: t()
  def new(data, opts \\ []) do
    name = Keyword.get(opts, :name, "test")
    %__MODULE__{data: data, name: name}
  end

  @doc """
  Creates an NLLEvaluator from a SupervisedDataset.
  """
  @spec from_dataset(Dataset.t(), keyword()) :: t()
  def from_dataset(dataset, opts \\ []) do
    all_data =
      0..(Dataset.length(dataset) - 1)
      |> Enum.flat_map(fn i -> Dataset.get_batch(dataset, i) end)

    new(all_data, opts)
  end

  @doc """
  Evaluates the NLL on the stored datums using the training client.
  """
  @impl true
  @spec evaluate(t(), term()) :: {:ok, map()} | {:error, term()}
  def evaluate(%__MODULE__{data: data, name: name}, training_client) do
    with {:ok, result} <- do_forward(training_client, data),
         {:ok, logprobs} <- extract_logprobs(result) do
      weights = extract_weights(data)
      nll = Common.compute_mean_nll(logprobs, weights)
      key = "#{name}/nll"
      {:ok, %{key => nll}}
    end
  end

  defp do_forward({ports, session}, datums) do
    case TrainingClient.forward_backward(ports, session, datums) do
      {:error, reason} -> {:error, reason}
      {:ok, future} -> TrainingClient.await(ports, future)
      future -> TrainingClient.await(ports, future)
    end
  end

  defp do_forward(training_client, datums) do
    module = training_client.__struct__

    cond do
      function_exported?(module, :forward, 2) ->
        call_task_result(module.forward(training_client, datums))

      function_exported?(module, :forward_backward, 2) ->
        call_task_result(module.forward_backward(training_client, datums))

      true ->
        {:error, :forward_not_supported}
    end
  end

  defp call_task_result({:ok, %Task{} = task}), do: Task.await(task, :infinity)
  defp call_task_result({:ok, result}), do: {:ok, result}
  defp call_task_result(%Task{} = task), do: Task.await(task, :infinity)
  defp call_task_result(other), do: other

  defp extract_logprobs(%{loss_fn_outputs: outputs}) when is_list(outputs) do
    {:ok, Enum.map(outputs, &extract_logprobs_from_output/1)}
  end

  defp extract_logprobs(%{"loss_fn_outputs" => outputs}) when is_list(outputs) do
    {:ok, Enum.map(outputs, &extract_logprobs_from_output/1)}
  end

  defp extract_logprobs(_), do: {:error, :missing_logprobs}

  defp extract_logprobs_from_output(output) do
    logprobs = output["logprobs"] || output[:logprobs] || output[:log_probs]

    cond do
      is_struct(logprobs, TensorData) -> logprobs
      is_list(logprobs) -> TensorData.from_list(logprobs, :float32)
      true -> TensorData.from_list([], :float32)
    end
  end

  defp extract_weights(datums) do
    Enum.map(datums, fn datum ->
      Datum.get_weights(datum)
    end)
  end
end
