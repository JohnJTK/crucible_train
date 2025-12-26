defmodule CrucibleTrain.Logging.PrettyPrintLogger do
  @moduledoc """
  Pretty printer logger for console output.
  """

  @behaviour CrucibleTrain.Logging.Logger

  require Logger

  alias CrucibleTrain.Logging.DumpConfig
  alias TableRex.Renderer.Text, as: TableRexText
  alias TableRex.Table

  defstruct [:table_opts]

  @type t :: %__MODULE__{
          table_opts: keyword()
        }

  @impl true
  def init(opts) do
    table_opts = Keyword.get(opts, :table_opts, TableRexText.default_options())
    {:ok, %__MODULE__{table_opts: Keyword.new(table_opts)}}
  end

  @impl true
  def log_metrics(%__MODULE__{table_opts: table_opts}, step, metrics) do
    rows =
      metrics
      |> Enum.sort_by(fn {k, _v} -> to_string(k) end)
      |> Enum.map(fn {k, v} -> [to_string(k), format_value(v)] end)

    {:ok, rendered} =
      rows
      |> Table.new(["Metric", "Value"])
      |> TableRexText.render(table_opts)

    prefix = if is_integer(step), do: "Step #{step}", else: "Metrics"
    Logger.info(prefix <> "\n" <> rendered)
    :ok
  end

  @impl true
  def log_hparams(%__MODULE__{table_opts: table_opts}, hparams) do
    rows =
      hparams
      |> DumpConfig.dump()
      |> Enum.sort_by(fn {k, _v} -> to_string(k) end)
      |> Enum.map(fn {k, v} -> [to_string(k), format_value(v)] end)

    {:ok, rendered} =
      rows
      |> Table.new(["Param", "Value"])
      |> TableRexText.render(table_opts)

    Logger.info("Hyperparameters\n" <> rendered)
    :ok
  end

  @impl true
  def log_long_text(_state, key, text) do
    Logger.info("#{key}:\n#{text}")
    :ok
  end

  @impl true
  def sync(_state), do: :ok

  @impl true
  def get_url(_state), do: nil

  @impl true
  def close(_state), do: :ok

  defp format_value(value) when is_float(value), do: Float.round(value, 6)
  defp format_value(value), do: inspect(value)
end
