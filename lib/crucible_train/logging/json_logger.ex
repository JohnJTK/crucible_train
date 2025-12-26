defmodule CrucibleTrain.Logging.JsonLogger do
  @moduledoc """
  JSONL logger for metrics and configuration.
  """

  @behaviour CrucibleTrain.Logging.Logger

  require Logger

  alias CrucibleTrain.Logging.DumpConfig

  defstruct [:log_dir, :metrics_file, :config_file]

  @type t :: %__MODULE__{
          log_dir: String.t(),
          metrics_file: Path.t(),
          config_file: Path.t()
        }

  @impl true
  def init(opts) do
    log_dir = Keyword.get(opts, :log_dir) || Keyword.get(opts, :log_path)

    if is_binary(log_dir) do
      log_dir = Path.expand(log_dir)
      File.mkdir_p!(log_dir)

      metrics_file = Path.join(log_dir, "metrics.jsonl")
      config_file = Path.join(log_dir, "config.json")

      {:ok,
       %__MODULE__{
         log_dir: log_dir,
         metrics_file: metrics_file,
         config_file: config_file
       }}
    else
      {:error, :missing_log_dir}
    end
  end

  @impl true
  def log_metrics(%__MODULE__{metrics_file: metrics_file}, step, metrics) do
    entry =
      if is_integer(step) do
        Map.put(metrics, :step, step)
      else
        metrics
      end

    json_line = Jason.encode!(DumpConfig.dump(entry)) <> "\n"
    File.write!(metrics_file, json_line, [:append])
    :ok
  end

  @impl true
  def log_hparams(%__MODULE__{config_file: config_file}, hparams) do
    config_map = DumpConfig.dump(hparams)
    json = Jason.encode!(config_map, pretty: true)
    File.write!(config_file, json)
    Logger.info("Logged config to #{config_file}")
    :ok
  end

  @impl true
  def log_long_text(%__MODULE__{log_dir: log_dir}, key, text) do
    filename = Path.join(log_dir, "#{key}.txt")
    File.write!(filename, text)
    :ok
  end

  @impl true
  def sync(_logger), do: :ok

  @impl true
  def get_url(_logger), do: nil

  @impl true
  def close(%__MODULE__{log_dir: log_dir}) do
    Logger.info("Closing logger for #{log_dir}")
    :ok
  end
end
