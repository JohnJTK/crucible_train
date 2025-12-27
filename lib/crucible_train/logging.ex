defmodule CrucibleTrain.Logging do
  @moduledoc """
  Convenience helpers for ML logging backends.
  """

  alias CrucibleTrain.Logging.{
    JsonLogger,
    MultiplexLogger,
    NeptuneLogger,
    PrettyPrintLogger,
    WandbLogger
  }

  @type logger :: {module(), term()}

  @doc """
  Creates a logger based on the given type or module.
  """
  @spec create_logger(atom() | module(), keyword()) :: {:ok, logger()} | {:error, term()}
  def create_logger(type, opts \\ []) do
    module = resolve_logger_module(type)

    case module.init(opts) do
      {:ok, state} -> {:ok, {module, state}}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Logs metrics using the logger.
  """
  @spec log_metrics(logger(), non_neg_integer() | nil, map()) :: :ok
  def log_metrics({module, state}, step, metrics) do
    module.log_metrics(state, step, metrics)
  end

  @doc """
  Logs hyperparameters using the logger.
  """
  @spec log_hparams(logger(), map()) :: :ok
  def log_hparams({module, state}, hparams) do
    module.log_hparams(state, hparams)
  end

  @doc """
  Logs long text if supported by the logger.
  """
  @spec log_long_text(logger(), String.t(), String.t()) :: :ok
  def log_long_text({module, state}, key, text) do
    if function_exported?(module, :log_long_text, 3) do
      module.log_long_text(state, key, text)
    end

    :ok
  end

  @doc """
  Syncs the logger if supported.
  """
  @spec sync(logger()) :: :ok
  def sync({module, state}) do
    if function_exported?(module, :sync, 1) do
      module.sync(state)
    end

    :ok
  end

  @doc """
  Returns the logger URL if available.
  """
  @spec get_url(logger()) :: String.t() | nil
  def get_url({module, state}) do
    if function_exported?(module, :get_url, 1) do
      module.get_url(state)
    else
      nil
    end
  end

  @doc """
  Closes the logger.
  """
  @spec close(logger()) :: :ok
  def close({module, state}) do
    module.close(state)
  end

  defp resolve_logger_module(:json), do: JsonLogger
  defp resolve_logger_module(:pretty), do: PrettyPrintLogger
  defp resolve_logger_module(:multiplex), do: MultiplexLogger
  defp resolve_logger_module(:wandb), do: WandbLogger
  defp resolve_logger_module(:neptune), do: NeptuneLogger
  defp resolve_logger_module(module) when is_atom(module), do: module
end
