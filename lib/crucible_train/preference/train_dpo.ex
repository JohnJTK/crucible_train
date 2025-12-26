defmodule CrucibleTrain.Preference.TrainDPO do
  @moduledoc """
  Simplified DPO training loop built on supervised training.
  """

  alias CrucibleTrain.Preference.TrainDPO.Config
  alias CrucibleTrain.Supervised

  defmodule Config do
    @moduledoc """
    Configuration for DPO training.
    """

    @type t :: %__MODULE__{
            training_client: term() | nil,
            ports: CrucibleTrain.Ports.t() | nil,
            training_config: map(),
            train_dataset: CrucibleTrain.Supervised.Dataset.t() | nil,
            learning_rate: float(),
            num_epochs: pos_integer(),
            log_path: String.t() | nil,
            logger: CrucibleTrain.Logging.logger() | nil
          }

    defstruct training_client: nil,
              ports: nil,
              training_config: %{},
              train_dataset: nil,
              learning_rate: 1.0e-4,
              num_epochs: 1,
              log_path: nil,
              logger: nil

    @spec new(keyword()) :: t()
    def new(opts) when is_list(opts), do: struct!(__MODULE__, opts)
  end

  @doc """
  Runs the DPO training loop.
  """
  @spec main(Config.t() | map()) :: {:ok, map()} | {:error, term()}
  def main(%Config{} = config) do
    supervised_config = %Supervised.Config{
      training_client: config.training_client,
      ports: config.ports,
      training_config: config.training_config,
      train_dataset: config.train_dataset,
      learning_rate: config.learning_rate,
      num_epochs: config.num_epochs,
      log_path: config.log_path,
      logger: config.logger
    }

    Supervised.Train.main(supervised_config)
  end

  def main(config) when is_map(config) do
    main(struct!(Config, config))
  end
end
