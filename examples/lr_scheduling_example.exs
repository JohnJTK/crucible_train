# Learning Rate Scheduling Example
#
# Demonstrates learning rate schedules including warmup support.
#
# Run with: mix run examples/lr_scheduling_example.exs

alias CrucibleTrain.Utils.LRScheduling

IO.puts("=== Learning Rate Scheduling Demo ===\n")

base_lr = 1.0e-4
total_steps = 100

IO.puts("Base learning rate: #{base_lr}")
IO.puts("Total steps: #{total_steps}")
IO.puts("")

# Helper to display schedule
display_schedule = fn schedule, name ->
  IO.puts("## #{name}")
  IO.puts("")

  steps = [0, 10, 25, 50, 75, 90, 100]

  for step <- steps do
    multiplier = LRScheduling.compute_schedule_lr_multiplier(schedule, step, total_steps)
    lr = base_lr * multiplier

    bar_width = round(multiplier * 30)
    bar = String.duplicate("#", bar_width) <> String.duplicate(" ", 30 - bar_width)

    IO.puts(
      "  Step #{String.pad_leading(Integer.to_string(step), 3)}: " <>
        "[#{bar}] " <>
        "mult=#{Float.round(multiplier, 4) |> Float.to_string() |> String.pad_trailing(6)} " <>
        "lr=#{:io_lib.format("~.2e", [lr])}"
    )
  end

  IO.puts("")
end

# --- Constant Schedule ---
display_schedule.(:constant, "Constant Schedule")

# --- Linear Decay Schedule ---
display_schedule.(:linear, "Linear Decay Schedule")

# --- Cosine Annealing Schedule ---
display_schedule.(:cosine, "Cosine Annealing Schedule")

# --- Warmup + Linear Decay ---
display_schedule.({:warmup, 20, :linear}, "Warmup (20 steps) + Linear Decay")

# --- Warmup + Cosine ---
display_schedule.({:warmup, 10, :cosine}, "Warmup (10 steps) + Cosine Annealing")

# --- Comparison Chart ---
IO.puts("## Schedule Comparison\n")

schedules = [
  {:constant, "Constant"},
  {:linear, "Linear"},
  {:cosine, "Cosine"},
  {{:warmup, 20, :cosine}, "Warmup+Cos"}
]

# Header
IO.write("  Step  ")

for {_schedule, name} <- schedules do
  IO.write(String.pad_trailing(name, 12))
end

IO.puts("")

IO.write("  ----  ")

for _ <- schedules do
  IO.write("----------  ")
end

IO.puts("")

# Values at key steps
for step <- [0, 5, 10, 15, 20, 30, 50, 75, 100] do
  IO.write("  #{String.pad_leading(Integer.to_string(step), 4)}  ")

  for {schedule, _name} <- schedules do
    multiplier = LRScheduling.compute_schedule_lr_multiplier(schedule, step, total_steps)
    IO.write(String.pad_trailing(Float.round(multiplier, 4) |> to_string(), 12))
  end

  IO.puts("")
end

IO.puts("\n## Usage in Training Config\n")

IO.puts("""
  alias CrucibleTrain.Supervised.Config

  # Simple cosine schedule
  config = %Config{
    learning_rate: 1.0e-4,
    lr_schedule: :cosine,
    # ...
  }

  # With warmup
  config = %Config{
    learning_rate: 1.0e-4,
    lr_schedule: {:warmup, 100, :cosine},
    # ...
  }
""")

IO.puts("Done!")
