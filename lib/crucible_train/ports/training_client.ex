defmodule CrucibleTrain.Ports.TrainingClient do
  @moduledoc """
  Port for training platform backends.
  """

  alias CrucibleTrain.Ports
  alias CrucibleTrain.Types.Datum

  @type adapter_opts :: keyword()
  @type session :: term()
  @type future :: term()
  @type loss_fn :: atom() | String.t()
  @type loss_fn_config :: map() | nil
  @type forward_backward_opts :: [
          loss_fn: loss_fn(),
          loss_fn_config: loss_fn_config()
        ]

  @callback start_session(adapter_opts(), config :: map()) :: {:ok, session()} | {:error, term()}
  @callback forward_backward(adapter_opts(), session(), [Datum.t()], forward_backward_opts()) ::
              future()
  @callback forward_backward_custom(
              adapter_opts(),
              session(),
              [Datum.t()],
              (list(Datum.t()), list(term()) -> {term(), map()}),
              keyword()
            ) :: future() | {:error, term()}
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
    forward_backward(ports, session, datums, [])
  end

  @spec forward_backward(Ports.t(), session(), [Datum.t()], forward_backward_opts()) :: future()
  def forward_backward(%Ports{} = ports, session, datums, opts) do
    {module, adapter_opts} = Ports.resolve(ports, :training_client)
    module.forward_backward(adapter_opts, session, datums, opts)
  end

  @spec forward_backward_custom(
          Ports.t(),
          session(),
          [Datum.t()],
          (list(Datum.t()), list(term()) -> {term(), map()}),
          keyword()
        ) :: future() | {:error, term()}
  def forward_backward_custom(%Ports{} = ports, session, datums, loss_fn, opts \\ []) do
    {module, adapter_opts} = Ports.resolve(ports, :training_client)
    module.forward_backward_custom(adapter_opts, session, datums, loss_fn, opts)
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
