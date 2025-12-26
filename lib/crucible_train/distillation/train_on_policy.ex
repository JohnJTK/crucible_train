defmodule CrucibleTrain.Distillation.TrainOnPolicy do
  @moduledoc """
  Simplified on-policy distillation loop.
  """

  require Logger

  alias CrucibleTrain.Logging
  alias CrucibleTrain.Ports.TrainingClient
  alias CrucibleTrain.RL.{DataProcessing, Rollouts}

  defmodule Config do
    @moduledoc """
    Configuration for on-policy distillation.
    """

    @type t :: %__MODULE__{
            rl_dataset: CrucibleTrain.RL.RLDataset.t() | nil,
            teacher_completer: struct() | nil,
            training_client: term() | nil,
            ports: CrucibleTrain.Ports.t() | nil,
            training_config: map(),
            learning_rate: float(),
            num_batches: pos_integer() | nil,
            log_path: String.t() | nil,
            logger: CrucibleTrain.Logging.logger() | nil
          }

    defstruct rl_dataset: nil,
              teacher_completer: nil,
              training_client: nil,
              ports: nil,
              training_config: %{},
              learning_rate: 1.0e-4,
              num_batches: nil,
              log_path: nil,
              logger: nil

    @spec new(keyword()) :: t()
    def new(opts) when is_list(opts), do: struct!(__MODULE__, opts)
  end

  @spec main(Config.t() | map()) :: {:ok, map()} | {:error, term()}
  def main(%Config{} = config), do: run(config)
  def main(config) when is_map(config), do: run(struct!(Config, config))

  defp run(%Config{} = config) do
    with {:ok, dataset} <- fetch_dataset(config),
         {:ok, teacher} <- fetch_teacher(config),
         {:ok, client_info} <- init_training_client(config),
         {:ok, logger} <- ensure_logger(config) do
      total_batches = config.num_batches || dataset.__struct__.length(dataset)

      metrics =
        Enum.map(0..(total_batches - 1), fn batch_idx ->
          env_group_builders = dataset.__struct__.get_batch(dataset, batch_idx)

          groups = Enum.map(env_group_builders, &Rollouts.do_group_rollout(&1, teacher))
          advantages = DataProcessing.compute_advantages(groups)
          {datums, _meta} = DataProcessing.assemble_training_data(groups, advantages)

          batch_metrics =
            case training_step(client_info, datums, config.learning_rate) do
              {:ok, result} -> result
              {:error, reason} -> %{error: inspect(reason)}
            end

          log_metrics(logger, batch_idx, batch_metrics)

          batch_metrics
        end)

      maybe_close_logger(logger)
      maybe_close_client(client_info)

      {:ok, %{metrics: metrics}}
    end
  end

  defp fetch_dataset(%Config{rl_dataset: %_{} = dataset}), do: {:ok, dataset}
  defp fetch_dataset(_), do: {:error, :missing_rl_dataset}

  defp fetch_teacher(%Config{teacher_completer: %_{} = teacher}), do: {:ok, teacher}
  defp fetch_teacher(_), do: {:error, :missing_teacher_completer}

  defp ensure_logger(%Config{logger: {module, state}}), do: {:ok, {module, state}}
  defp ensure_logger(%Config{log_path: nil}), do: {:ok, nil}

  defp ensure_logger(%Config{log_path: log_path}) do
    Logging.create_logger(:json, log_dir: log_path)
  end

  defp log_metrics(nil, _step, _metrics), do: :ok
  defp log_metrics(logger, step, metrics), do: Logging.log_metrics(logger, step, metrics)

  defp maybe_close_logger(nil), do: :ok
  defp maybe_close_logger(logger), do: Logging.close(logger)

  defp init_training_client(%Config{training_client: {ports, session}}) do
    {:ok, {:ports, ports, session, :external}}
  end

  defp init_training_client(%Config{training_client: training_client})
       when not is_nil(training_client) do
    {:ok, {:client, training_client}}
  end

  defp init_training_client(%Config{ports: %CrucibleTrain.Ports{} = ports} = config) do
    case TrainingClient.start_session(ports, config.training_config) do
      {:ok, session} -> {:ok, {:ports, ports, session, :owned}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp init_training_client(_), do: {:error, :missing_training_client}

  defp training_step(client_info, datums, learning_rate) do
    with {:ok, fb_result} <- forward_backward(client_info, datums),
         {:ok, _optim_result} <- optim_step(client_info, learning_rate) do
      metrics = fb_result[:metrics] || fb_result["metrics"] || %{}
      {:ok, metrics}
    end
  end

  defp forward_backward({:ports, ports, session, _ownership}, datums) do
    case TrainingClient.forward_backward(ports, session, datums) do
      {:error, reason} -> {:error, reason}
      {:ok, future} -> TrainingClient.await(ports, future)
      future -> TrainingClient.await(ports, future)
    end
  end

  defp forward_backward({:client, client}, datums) do
    case apply_client(client, :forward_backward, [client, datums]) do
      {:ok, %Task{} = task} -> Task.await(task, :infinity)
      {:ok, result} -> {:ok, result}
      %Task{} = task -> Task.await(task, :infinity)
      other -> other
    end
  end

  defp optim_step({:ports, ports, session, _ownership}, learning_rate) do
    case TrainingClient.optim_step(ports, session, learning_rate) do
      {:error, reason} -> {:error, reason}
      {:ok, future} -> TrainingClient.await(ports, future)
      future -> TrainingClient.await(ports, future)
    end
  end

  defp optim_step({:client, client}, learning_rate) do
    case apply_client(client, :optim_step, [client, learning_rate]) do
      {:ok, %Task{} = task} -> Task.await(task, :infinity)
      {:ok, result} -> {:ok, result}
      %Task{} = task -> Task.await(task, :infinity)
      other -> other
    end
  end

  defp apply_client(client, fun, args) do
    module = client.__struct__
    apply(module, fun, args)
  end

  defp maybe_close_client({:ports, ports, session, :owned}) do
    TrainingClient.close_session(ports, session)
  end

  defp maybe_close_client(_), do: :ok
end
