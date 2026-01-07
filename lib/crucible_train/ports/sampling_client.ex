defmodule CrucibleTrain.Ports.SamplingClient do
  @moduledoc """
  Port for sampling/inference services that return token-level outputs.
  """

  alias CrucibleTrain.Ports

  @type adapter_opts :: keyword()
  @type session :: term()
  @type future :: term()
  @type model_input :: term()
  @type params :: map()

  @callback start_session(adapter_opts(), config :: map()) :: {:ok, session()} | {:error, term()}
  @callback sample(adapter_opts(), session(), model_input(), params(), keyword()) ::
              {:ok, future()} | {:error, term()}
  @callback sample_stream(adapter_opts(), session(), model_input(), params(), keyword()) ::
              {:ok, Enumerable.t()} | {:error, term()}
  @callback compute_logprobs(adapter_opts(), session(), model_input(), keyword()) ::
              {:ok, future()} | {:error, term()}
  @callback await(adapter_opts(), future()) :: {:ok, term()} | {:error, term()}
  @callback close_session(adapter_opts(), session()) :: :ok

  @spec start_session(Ports.t(), map()) :: {:ok, session()} | {:error, term()}
  def start_session(%Ports{} = ports, config) do
    {module, adapter_opts} = Ports.resolve(ports, :sampling_client)
    module.start_session(adapter_opts, config)
  end

  @spec sample(Ports.t(), session(), model_input(), params(), keyword()) ::
          {:ok, future()} | {:error, term()}
  def sample(%Ports{} = ports, session, model_input, params, opts \\ []) do
    {module, adapter_opts} = Ports.resolve(ports, :sampling_client)
    module.sample(adapter_opts, session, model_input, params, opts)
  end

  @spec sample_stream(Ports.t(), session(), model_input(), params(), keyword()) ::
          {:ok, Enumerable.t()} | {:error, term()}
  def sample_stream(%Ports{} = ports, session, model_input, params, opts \\ []) do
    {module, adapter_opts} = Ports.resolve(ports, :sampling_client)
    module.sample_stream(adapter_opts, session, model_input, params, opts)
  end

  @spec compute_logprobs(Ports.t(), session(), model_input(), keyword()) ::
          {:ok, future()} | {:error, term()}
  def compute_logprobs(%Ports{} = ports, session, model_input, opts \\ []) do
    {module, adapter_opts} = Ports.resolve(ports, :sampling_client)
    module.compute_logprobs(adapter_opts, session, model_input, opts)
  end

  @spec await(Ports.t(), future()) :: {:ok, term()} | {:error, term()}
  def await(%Ports{} = ports, future) do
    {module, adapter_opts} = Ports.resolve(ports, :sampling_client)
    module.await(adapter_opts, future)
  end

  @spec close_session(Ports.t(), session()) :: :ok
  def close_session(%Ports{} = ports, session) do
    {module, adapter_opts} = Ports.resolve(ports, :sampling_client)
    module.close_session(adapter_opts, session)
  end
end
