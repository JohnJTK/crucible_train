defmodule CrucibleTrain.Supervised.Config do
  @moduledoc """
  Configuration for supervised fine-tuning.
  """

  alias CrucibleTrain.Ports
  alias CrucibleTrain.Supervised.Dataset

  @type lr_schedule :: :linear | :cosine | :constant | String.t()

  @type t :: %__MODULE__{
          training_client: term() | nil,
          ports: Ports.t() | nil,
          training_config: map(),
          train_dataset: Dataset.t() | nil,
          learning_rate: float(),
          lr_schedule: lr_schedule(),
          num_epochs: pos_integer(),
          batch_size: pos_integer() | nil,
          log_path: String.t() | nil,
          logger: CrucibleTrain.Logging.logger() | nil,
          save_every: non_neg_integer(),
          eval_every: non_neg_integer(),
          adam_beta1: float(),
          adam_beta2: float(),
          adam_eps: float()
        }

  defstruct training_client: nil,
            ports: nil,
            training_config: %{},
            train_dataset: nil,
            learning_rate: 1.0e-4,
            lr_schedule: :linear,
            num_epochs: 1,
            batch_size: nil,
            log_path: nil,
            logger: nil,
            save_every: 0,
            eval_every: 0,
            adam_beta1: 0.9,
            adam_beta2: 0.95,
            adam_eps: 1.0e-8

  @doc """
  Creates a new config with the given options.
  """
  @spec new(keyword()) :: t()
  def new(opts) when is_list(opts) do
    struct!(__MODULE__, opts)
  end

  @doc """
  Expands the log_path, handling ~ for home directory.
  """
  @spec expand_log_path(t()) :: t()
  def expand_log_path(%__MODULE__{log_path: nil} = config), do: config

  def expand_log_path(%__MODULE__{log_path: path} = config) do
    %{config | log_path: Path.expand(path)}
  end
end
