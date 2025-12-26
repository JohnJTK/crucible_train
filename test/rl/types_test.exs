defmodule CrucibleTrain.RL.TypesTest do
  use ExUnit.Case, async: true

  alias CrucibleTrain.RL.{Trajectory, TrajectoryGroup, Transition}
  alias CrucibleTrain.Types.{ModelInput, TokensWithLogprobs}

  test "trajectory_group total rewards sums step and final rewards" do
    ob = ModelInput.from_ints([1])
    ac = %TokensWithLogprobs{tokens: [2], maybe_logprobs: [-0.1]}

    traj = %Trajectory{
      transitions: [
        %Transition{ob: ob, ac: ac, reward: 1.0, episode_done: false, metrics: %{}},
        %Transition{ob: ob, ac: ac, reward: 2.0, episode_done: true, metrics: %{}}
      ],
      final_ob: ob
    }

    group = %TrajectoryGroup{
      trajectories_G: [traj],
      final_rewards_G: [0.5],
      metrics_G: [%{}]
    }

    assert TrajectoryGroup.get_total_rewards(group) == [3.5]
  end
end
