defmodule CrucibleTrain.Logging.MultiplexLogger do
  @moduledoc """
  Logger that forwards to multiple backends.
  """

  @behaviour CrucibleTrain.Logging.Logger

  defstruct [:loggers]

  @type logger_ref :: {module(), term()}
  @type t :: %__MODULE__{loggers: [logger_ref()]}

  @impl true
  def init(opts) do
    logger_specs = Keyword.get(opts, :loggers, [])

    with {:ok, loggers} <- init_loggers(logger_specs) do
      {:ok, %__MODULE__{loggers: loggers}}
    end
  end

  @impl true
  def log_metrics(%__MODULE__{loggers: loggers}, step, metrics) do
    Enum.each(loggers, fn {module, state} ->
      module.log_metrics(state, step, metrics)
    end)

    :ok
  end

  @impl true
  def log_hparams(%__MODULE__{loggers: loggers}, hparams) do
    Enum.each(loggers, fn {module, state} ->
      module.log_hparams(state, hparams)
    end)

    :ok
  end

  @impl true
  def log_long_text(%__MODULE__{loggers: loggers}, key, text) do
    Enum.each(loggers, fn {module, state} ->
      if function_exported?(module, :log_long_text, 3) do
        module.log_long_text(state, key, text)
      end
    end)

    :ok
  end

  @impl true
  def sync(%__MODULE__{loggers: loggers}) do
    Enum.each(loggers, fn {module, state} ->
      if function_exported?(module, :sync, 1) do
        module.sync(state)
      end
    end)

    :ok
  end

  @impl true
  def get_url(%__MODULE__{loggers: loggers}) do
    loggers
    |> Enum.find_value(fn {module, state} ->
      if function_exported?(module, :get_url, 1) do
        module.get_url(state)
      else
        nil
      end
    end)
  end

  @impl true
  def close(%__MODULE__{loggers: loggers}) do
    Enum.each(loggers, fn {module, state} ->
      module.close(state)
    end)

    :ok
  end

  defp init_loggers(logger_specs) do
    logger_specs
    |> Enum.reduce_while({:ok, []}, fn spec, {:ok, acc} ->
      case init_logger_spec(spec) do
        {:ok, logger} -> {:cont, {:ok, acc ++ [logger]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp init_logger_spec({module, opts}) when is_atom(module) and is_list(opts) do
    case module.init(opts) do
      {:ok, state} -> {:ok, {module, state}}
      {:error, reason} -> {:error, {module, reason}}
    end
  end

  defp init_logger_spec(module) when is_atom(module) do
    case module.init([]) do
      {:ok, state} -> {:ok, {module, state}}
      {:error, reason} -> {:error, {module, reason}}
    end
  end

  defp init_logger_spec(other), do: {:error, {:invalid_logger_spec, other}}
end
