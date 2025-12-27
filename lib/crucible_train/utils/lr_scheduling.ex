defmodule CrucibleTrain.Utils.LRScheduling do
  @moduledoc """
  Learning rate schedule helpers.
  """

  @type lr_schedule ::
          :linear | :cosine | :constant | String.t() | {:warmup, non_neg_integer(), lr_schedule()}

  @spec compute_schedule_lr_multiplier(
          {:warmup, non_neg_integer(), lr_schedule()},
          non_neg_integer(),
          pos_integer()
        ) :: float()
  def compute_schedule_lr_multiplier({:warmup, warmup_steps, schedule}, step, total_steps) do
    if step < warmup_steps do
      step / warmup_steps
    else
      adjusted_step = step - warmup_steps
      adjusted_total = max(total_steps - warmup_steps, 1)
      compute_schedule_lr_multiplier(schedule, adjusted_step, adjusted_total)
    end
  end

  @spec compute_schedule_lr_multiplier(lr_schedule(), non_neg_integer(), pos_integer()) :: float()
  def compute_schedule_lr_multiplier(lr_schedule, step, total_steps) do
    schedule = normalize_schedule(lr_schedule)

    case schedule do
      :linear ->
        1.0 - step / total_steps

      :cosine ->
        0.5 * (1.0 + :math.cos(:math.pi() * step / total_steps))

      :constant ->
        1.0

      other ->
        raise ArgumentError, "Unknown learning rate schedule: #{inspect(other)}"
    end
  end

  defp normalize_schedule(schedule) when is_atom(schedule), do: schedule

  defp normalize_schedule(schedule) when is_binary(schedule) do
    schedule
    |> String.downcase()
    |> String.to_existing_atom()
  rescue
    _ -> schedule
  end
end
