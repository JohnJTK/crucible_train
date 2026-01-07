defmodule CrucibleTrain.Adapters.Noop.TrainingClient do
  @moduledoc """
  No-op adapter for training backends.
  """

  @behaviour CrucibleTrain.Ports.TrainingClient

  alias CrucibleTrain.Ports.Error

  defp error do
    Error.new(:training_client, __MODULE__, "Training adapter is not configured")
  end

  @impl true
  def start_session(_opts, _config), do: {:error, error()}

  @impl true
  def forward_backward(_opts, _session, _datums, _opts_kw), do: {:error, error()}

  @impl true
  def forward_backward_custom(_opts, _session, _datums, _loss_fn, _opts_kw), do: {:error, error()}

  @impl true
  def optim_step(_opts, _session, _learning_rate), do: {:error, error()}

  @impl true
  def await(_opts, _future), do: {:error, error()}

  @impl true
  def save_checkpoint(_opts, _session, _path), do: {:error, error()}

  @impl true
  def load_checkpoint(_opts, _session, _path), do: {:error, error()}

  @impl true
  def close_session(_opts, _session), do: :ok
end
