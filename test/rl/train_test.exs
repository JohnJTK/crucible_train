defmodule CrucibleTrain.RL.TrainTest do
  use ExUnit.Case, async: true

  alias CrucibleTrain.Completers.MockCompleter
  alias CrucibleTrain.RL.Train
  alias CrucibleTrain.Types.{ModelInput, TokensWithLogprobs}

  defmodule EnvStub do
    @behaviour CrucibleTrain.RL.Env

    defstruct []

    @impl true
    def initial_observation(_env) do
      {ModelInput.from_ints([1]), []}
    end

    @impl true
    def step(_env, _action) do
      %CrucibleTrain.RL.StepResult{
        reward: 1.0,
        episode_done: true,
        next_observation: ModelInput.empty(),
        next_stop_condition: [],
        metrics: %{}
      }
    end
  end

  defmodule BuilderStub do
    @behaviour CrucibleTrain.RL.EnvGroupBuilder
    defstruct []

    @impl true
    def make_envs(_builder), do: [%EnvStub{}]

    @impl true
    def compute_group_rewards(_builder, _trajectories, _envs), do: [{0.0, %{}}]

    @impl true
    def logging_tags(_builder), do: []
  end

  defmodule TrainingClientStub do
    defstruct []

    def forward_backward(_client, _batch) do
      {:ok, Task.async(fn -> {:ok, %{metrics: %{}}} end)}
    end

    def optim_step(_client, _lr) do
      {:ok, Task.async(fn -> {:ok, %{}} end)}
    end
  end

  test "rl train runs one batch" do
    token_result = %TokensWithLogprobs{tokens: [2], maybe_logprobs: [-0.1]}
    completer = MockCompleter.new(token_result: token_result)

    config = %Train.Config{
      env_group_builder: %BuilderStub{},
      token_completer: completer,
      training_client: %TrainingClientStub{},
      num_batches: 1,
      learning_rate: 1.0e-4
    }

    assert {:ok, result} = Train.main(config)
    assert length(result.metrics) == 1
  end
end
