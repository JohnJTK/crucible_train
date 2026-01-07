defmodule CrucibleTrain.Adapters.Noop.SamplingClient do
  @moduledoc """
  No-op adapter for sampling backends.
  """

  @behaviour CrucibleTrain.Ports.SamplingClient

  alias CrucibleTrain.Ports.Error

  defp error do
    Error.new(:sampling_client, __MODULE__, "Sampling adapter is not configured")
  end

  @impl true
  def start_session(_opts, _config), do: {:error, error()}

  @impl true
  def sample(_opts, _session, _model_input, _params, _opts_kw), do: {:error, error()}

  @impl true
  def sample_stream(_opts, _session, _model_input, _params, _opts_kw), do: {:error, error()}

  @impl true
  def compute_logprobs(_opts, _session, _model_input, _opts_kw), do: {:error, error()}

  @impl true
  def await(_opts, _future), do: {:error, error()}

  @impl true
  def close_session(_opts, _session), do: :ok
end
