defmodule CrucibleTrain.Supervised.Train do
  @moduledoc """
  Supervised training orchestration.
  """

  require Logger

  alias CrucibleTrain.Logging
  alias CrucibleTrain.Ports.TrainingClient
  alias CrucibleTrain.Supervised.{Config, Dataset}
  alias CrucibleTrain.Utils.LRScheduling

  @doc """
  Runs the supervised training loop.
  """
  @spec main(Config.t()) :: {:ok, map()} | {:error, term()}
  def main(%Config{} = config) do
    config = Config.expand_log_path(config)

    with {:ok, dataset} <- fetch_dataset(config),
         {:ok, client_info} <- init_training_client(config),
         {:ok, logger} <- ensure_logger(config) do
      total_steps = Dataset.length(dataset) * config.num_epochs

      log_hparams(logger, config)

      {metrics, final_state} =
        Enum.reduce(0..(config.num_epochs - 1), {[], client_info}, fn epoch_idx, {acc, client} ->
          dataset = Dataset.set_epoch(dataset, epoch_idx)

          {epoch_metrics, client} =
            run_epoch(dataset, epoch_idx, total_steps, config, client, logger)

          {acc ++ epoch_metrics, client}
        end)

      maybe_close_logger(logger)
      maybe_close_client(final_state)

      last_metrics = List.last(metrics) || %{}

      {:ok,
       %{
         total_steps: total_steps,
         final_metrics: last_metrics,
         metrics: metrics
       }}
    end
  end

  defp fetch_dataset(%Config{train_dataset: dataset}) when is_struct(dataset), do: {:ok, dataset}

  defp fetch_dataset(_), do: {:error, :missing_train_dataset}

  defp ensure_logger(%Config{logger: {module, state}}), do: {:ok, {module, state}}

  defp ensure_logger(%Config{log_path: nil}), do: {:ok, nil}

  defp ensure_logger(%Config{log_path: log_path}) do
    Logging.create_logger(:json, log_dir: log_path)
  end

  defp log_hparams(nil, _config), do: :ok

  defp log_hparams(logger, config) do
    Logging.log_hparams(logger, Map.from_struct(config))
  end

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

  defp run_epoch(dataset, epoch_idx, total_steps, config, client_info, logger) do
    n_batches = Dataset.length(dataset)

    if n_batches == 0 do
      {[], client_info}
    else
      Enum.reduce(0..(n_batches - 1), {[], client_info}, fn batch_idx, {acc, client} ->
        batch = Dataset.get_batch(dataset, batch_idx)
        step = epoch_idx * n_batches + batch_idx

        lr = compute_lr(config.learning_rate, step, total_steps, config.lr_schedule)

        adam_params = %{
          learning_rate: lr,
          beta1: config.adam_beta1,
          beta2: config.adam_beta2,
          eps: config.adam_eps
        }

        {metrics, client} = training_step(client, batch, lr, adam_params)

        step_metrics =
          Map.merge(metrics, %{
            "step" => step,
            "epoch" => epoch_idx,
            "batch" => batch_idx,
            "learning_rate" => lr
          })

        log_metrics(logger, step, step_metrics)

        {acc ++ [step_metrics], client}
      end)
    end
  end

  defp training_step(client_info, batch, learning_rate, adam_params) do
    with {:ok, fb_result} <- forward_backward(client_info, batch),
         {:ok, _optim_result} <- optim_step(client_info, learning_rate, adam_params) do
      metrics = fb_result[:metrics] || fb_result["metrics"] || %{}
      {metrics, client_info}
    else
      {:error, reason} ->
        Logger.error("Training step failed: #{inspect(reason)}")
        {%{"error" => inspect(reason)}, client_info}
    end
  end

  defp forward_backward({:ports, ports, session, _ownership}, batch) do
    case TrainingClient.forward_backward(ports, session, batch) do
      {:error, reason} -> {:error, reason}
      {:ok, future} -> TrainingClient.await(ports, future)
      future -> TrainingClient.await(ports, future)
    end
  end

  defp forward_backward({:client, client}, batch) do
    case apply_client(client, :forward_backward, [client, batch]) do
      {:ok, %Task{} = task} -> Task.await(task, :infinity)
      {:ok, result} -> {:ok, result}
      %Task{} = task -> Task.await(task, :infinity)
      other -> other
    end
  end

  defp optim_step({:ports, ports, session, _ownership}, learning_rate, _adam_params) do
    case TrainingClient.optim_step(ports, session, learning_rate) do
      {:error, reason} -> {:error, reason}
      {:ok, future} -> TrainingClient.await(ports, future)
      future -> TrainingClient.await(ports, future)
    end
  end

  defp optim_step({:client, client}, _learning_rate, adam_params) do
    case apply_client(client, :optim_step, [client, adam_params]) do
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

  defp log_metrics(nil, _step, _metrics), do: :ok

  defp log_metrics(logger, step, metrics) do
    Logging.log_metrics(logger, step, metrics)
  end

  defp maybe_close_client({:ports, ports, session, :owned}) do
    TrainingClient.close_session(ports, session)
  end

  defp maybe_close_client(_), do: :ok

  @doc """
  Computes the learning rate for a given step using the specified schedule.
  """
  @spec compute_lr(float(), non_neg_integer(), pos_integer(), Config.lr_schedule()) :: float()
  def compute_lr(base_lr, step, total_steps, schedule) do
    denom = if total_steps > 0, do: total_steps, else: 1

    multiplier =
      LRScheduling.compute_schedule_lr_multiplier(
        schedule,
        step,
        denom
      )

    base_lr * multiplier
  end
end
