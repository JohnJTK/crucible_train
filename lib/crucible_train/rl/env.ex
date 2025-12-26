defmodule CrucibleTrain.RL.Env do
  @moduledoc """
  Behaviour for a single-use RL environment.
  """

  alias CrucibleTrain.Completers.TokenCompleter
  alias CrucibleTrain.RL.{StepResult, Types}

  @callback initial_observation(env :: struct()) ::
              {Types.observation(), TokenCompleter.stop_condition()}
  @callback step(env :: struct(), Types.action()) :: StepResult.t()
end
