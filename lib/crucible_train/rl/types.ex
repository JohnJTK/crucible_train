defmodule CrucibleTrain.RL.Types do
  @moduledoc """
  Basic RL type aliases.
  """

  alias CrucibleTrain.Types.ModelInput

  @type action :: [integer()]
  @type observation :: ModelInput.t()
  @type logprobs :: [float()]
  @type metrics :: %{String.t() => float() | integer()}
end

defmodule CrucibleTrain.RL.StepResult do
  @moduledoc """
  Result of a single environment step.
  """

  alias CrucibleTrain.Completers.TokenCompleter
  alias CrucibleTrain.RL.Types

  @type t :: %__MODULE__{
          reward: float(),
          episode_done: boolean(),
          next_observation: Types.observation(),
          next_stop_condition: TokenCompleter.stop_condition(),
          metrics: Types.metrics()
        }

  defstruct [:reward, :episode_done, :next_observation, :next_stop_condition, metrics: %{}]
end

defmodule CrucibleTrain.RL.Transition do
  @moduledoc """
  Single transition (observation + action + reward).
  """

  alias CrucibleTrain.RL.Types
  alias CrucibleTrain.Types.TokensWithLogprobs

  @type t :: %__MODULE__{
          ob: Types.observation(),
          ac: TokensWithLogprobs.t(),
          reward: float(),
          episode_done: boolean(),
          metrics: Types.metrics()
        }

  defstruct [:ob, :ac, :reward, :episode_done, metrics: %{}]
end

defmodule CrucibleTrain.RL.Trajectory do
  @moduledoc """
  Sequence of transitions for a single environment rollout.
  """

  alias CrucibleTrain.RL.{Transition, Types}

  @type t :: %__MODULE__{
          transitions: [Transition.t()],
          final_ob: Types.observation()
        }

  defstruct [:transitions, :final_ob]
end

defmodule CrucibleTrain.RL.TrajectoryGroup do
  @moduledoc """
  Group of trajectories with group-level rewards and metrics.
  """

  alias CrucibleTrain.RL.Trajectory
  alias CrucibleTrain.Utils.MiscUtils

  @type t :: %__MODULE__{
          trajectories_G: [Trajectory.t()],
          final_rewards_G: [float()],
          metrics_G: [map()]
        }

  defstruct [:trajectories_G, :final_rewards_G, :metrics_G]

  @spec get_total_rewards(t()) :: [float()]
  def get_total_rewards(%__MODULE__{} = group) do
    MiscUtils.safezip([group.trajectories_G, group.final_rewards_G])
    |> Enum.map(fn {traj, final_reward} ->
      step_rewards = Enum.reduce(traj.transitions, 0.0, fn t, acc -> acc + t.reward end)
      step_rewards + final_reward
    end)
  end
end
