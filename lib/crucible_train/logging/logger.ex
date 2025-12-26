defmodule CrucibleTrain.Logging.Logger do
  @moduledoc """
  Behaviour for ML logging backends.
  """

  @type state :: term()

  @callback init(opts :: keyword()) :: {:ok, state()} | {:error, term()}
  @callback log_metrics(state(), step :: non_neg_integer(), metrics :: map()) :: :ok
  @callback log_hparams(state(), hparams :: map()) :: :ok
  @callback close(state()) :: :ok

  @optional_callbacks [log_long_text: 3, sync: 1, get_url: 1]
  @callback log_long_text(state(), key :: String.t(), text :: String.t()) :: :ok
  @callback sync(state()) :: :ok
  @callback get_url(state()) :: String.t() | nil
end
