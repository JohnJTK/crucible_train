defmodule CrucibleTrain.Ports.TrainingClient do
  @moduledoc """
  Port for training platform backends.
  """

  alias CrucibleTrain.Ports
  alias CrucibleTrain.Types.Datum

  @type adapter_opts :: keyword()
  @type session :: term()
  @type future :: term()

  @callback start_session(adapter_opts(), config :: map()) :: {:ok, session()} | {:error, term()}
  @callback forward_backward(adapter_opts(), session(), [Datum.t()]) :: future()
  @callback optim_step(adapter_opts(), session(), learning_rate :: float()) :: future()
  @callback await(adapter_opts(), future()) :: {:ok, map()} | {:error, term()}
  @callback save_checkpoint(adapter_opts(), session(), path :: String.t()) ::
              :ok | {:error, term()}
  @callback load_checkpoint(adapter_opts(), session(), path :: String.t()) ::
              :ok | {:error, term()}
  @callback close_session(adapter_opts(), session()) :: :ok

  @spec start_session(Ports.t(), map()) :: {:ok, session()} | {:error, term()}
  def start_session(%Ports{} = ports, config) do
    {module, adapter_opts} = Ports.resolve(ports, :training_client)
    module.start_session(adapter_opts, config)
  end

  @spec forward_backward(Ports.t(), session(), [Datum.t()]) :: future()
  def forward_backward(%Ports{} = ports, session, datums) do
    {module, adapter_opts} = Ports.resolve(ports, :training_client)
    module.forward_backward(adapter_opts, session, datums)
  end

  @spec optim_step(Ports.t(), session(), float()) :: future()
  def optim_step(%Ports{} = ports, session, learning_rate) do
    {module, adapter_opts} = Ports.resolve(ports, :training_client)
    module.optim_step(adapter_opts, session, learning_rate)
  end

  @spec await(Ports.t(), future()) :: {:ok, map()} | {:error, term()}
  def await(%Ports{} = ports, future) do
    {module, adapter_opts} = Ports.resolve(ports, :training_client)
    module.await(adapter_opts, future)
  end

  @spec save_checkpoint(Ports.t(), session(), String.t()) :: :ok | {:error, term()}
  def save_checkpoint(%Ports{} = ports, session, path) do
    {module, adapter_opts} = Ports.resolve(ports, :training_client)
    module.save_checkpoint(adapter_opts, session, path)
  end

  @spec load_checkpoint(Ports.t(), session(), String.t()) :: :ok | {:error, term()}
  def load_checkpoint(%Ports{} = ports, session, path) do
    {module, adapter_opts} = Ports.resolve(ports, :training_client)
    module.load_checkpoint(adapter_opts, session, path)
  end

  @spec close_session(Ports.t(), session()) :: :ok
  def close_session(%Ports{} = ports, session) do
    {module, adapter_opts} = Ports.resolve(ports, :training_client)
    module.close_session(adapter_opts, session)
  end
end
