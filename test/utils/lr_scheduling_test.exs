defmodule CrucibleTrain.Utils.LRSchedulingTest do
  use ExUnit.Case, async: true

  alias CrucibleTrain.Utils.LRScheduling

  describe "compute_schedule_lr_multiplier/3" do
    test "handles linear schedule" do
      assert_in_delta LRScheduling.compute_schedule_lr_multiplier(:linear, 0, 10), 1.0, 1.0e-6
      assert_in_delta LRScheduling.compute_schedule_lr_multiplier(:linear, 5, 10), 0.5, 1.0e-6
    end

    test "handles warmup schedule" do
      schedule = {:warmup, 5, :linear}

      assert_in_delta LRScheduling.compute_schedule_lr_multiplier(schedule, 0, 20), 0.0, 1.0e-6
      assert_in_delta LRScheduling.compute_schedule_lr_multiplier(schedule, 2, 20), 0.4, 1.0e-6
      assert_in_delta LRScheduling.compute_schedule_lr_multiplier(schedule, 5, 20), 1.0, 1.0e-6

      assert_in_delta LRScheduling.compute_schedule_lr_multiplier(schedule, 10, 20),
                      0.666666,
                      1.0e-3
    end
  end
end
