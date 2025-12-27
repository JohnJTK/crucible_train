# CrucibleTrain

<p align="center">
  <img src="assets/crucible_train.svg" alt="CrucibleTrain Logo" width="200"/>
</p>

<p align="center">
  <strong>Unified ML training infrastructure for Elixir/BEAM</strong>
</p>

<p align="center">
  <a href="https://hex.pm/packages/crucible_train"><img src="https://img.shields.io/hexpm/v/crucible_train.svg" alt="Hex Version"/></a>
  <a href="https://hexdocs.pm/crucible_train"><img src="https://img.shields.io/badge/hex-docs-blue.svg" alt="Hex Docs"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License"/></a>
</p>

---

CrucibleTrain provides a complete, platform-agnostic training infrastructure for ML workloads on the BEAM. It includes:

- **Renderers**: Message-to-token transformation for all major model families (Llama3, Qwen3, DeepSeek, etc.)
- **Training Loops**: Supervised learning, RL, DPO, and distillation
- **Type System**: Unified Datum, ModelInput, and related types
- **Ports & Adapters**: Pluggable backends for any training platform
- **Logging**: Multiplexed ML logging (JSON, console, custom backends)
- **Crucible Integration**: Stage implementations for pipeline composition

## Installation

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:crucible_train, "~> 0.2.0"}
  ]
end
```

## Quick Start

```elixir
alias CrucibleTrain.Supervised.{Train, Config}
alias CrucibleTrain.Renderers

renderer = Renderers.get_renderer("meta-llama/Llama-3.1-8B")

config = %Config{
  training_client: my_client,
  train_dataset: my_dataset,
  learning_rate: 1.0e-4,
  num_epochs: 3
}

{:ok, result} = Train.main(config)
```

## Training Stages

This package provides Crucible stages for ML training workflows:

| Stage | Name | Description |
|-------|------|-------------|
| `SupervisedTrain` | `:supervised_train` | Standard supervised learning with configurable optimizer/loss |
| `DPOTrain` | `:dpo_train` | Direct Preference Optimization with beta parameter |
| `RLTrain` | `:rl_train` | Reinforcement Learning (PPO, DQN, A2C, REINFORCE) |
| `Distillation` | `:distillation` | Knowledge Distillation with temperature/alpha |

All stages implement the `Crucible.Stage` behaviour with full `describe/1` schemas for introspection.

```elixir
# View stage schema
schema = CrucibleTrain.Stages.SupervisedTrain.describe(%{})
# => %{
#      name: :supervised_train,
#      description: "Runs supervised learning training...",
#      required: [],
#      optional: [:epochs, :batch_size, :learning_rate, :optimizer, :loss_fn, :metrics],
#      types: %{epochs: :integer, batch_size: :integer, ...}
#    }
```

Use in Crucible pipelines:

```elixir
alias CrucibleIR.StageDef

stages = [
  %StageDef{name: :supervised_train, options: %{epochs: 3, batch_size: 32}}
]
```

## Logging Backends

CrucibleTrain supports multiple logging backends for experiment tracking:

```elixir
alias CrucibleTrain.Logging

# Local JSONL logging
{:ok, logger} = Logging.create_logger(:json, log_dir: "./logs")

# Console table output
{:ok, logger} = Logging.create_logger(:pretty)

# Log metrics and hyperparameters
Logging.log_hparams(logger, %{learning_rate: 1.0e-4})
Logging.log_metrics(logger, step, %{loss: 0.5, accuracy: 0.9})
Logging.close(logger)
```

### Weights & Biases Integration

Full integration with [Weights & Biases](https://wandb.ai) for experiment tracking:

```elixir
# Setup: export WANDB_API_KEY="your-api-key"

{:ok, logger} = Logging.create_logger(:wandb,
  api_key: System.get_env("WANDB_API_KEY"),
  project: "my-project",
  entity: "my-team",           # optional
  run_name: "experiment-1"     # optional
)

# Get run URL
url = Logging.get_url(logger)
# => "https://wandb.ai/my-team/my-project/runs/experiment-1"

# Log hyperparameters (nested maps supported)
Logging.log_hparams(logger, %{
  model: "llama-3.1-8b",
  optimizer: %{name: "adamw", lr: 1.0e-4}
})

# Log training metrics
Logging.log_metrics(logger, step, %{loss: 0.5, accuracy: 0.9})

# Log long-form text (summaries, notes)
Logging.log_long_text(logger, "eval_notes", "Model performed well on...")

Logging.close(logger)
```

**Rate Limiting**: W&B free tier has strict rate limits (~60 requests/minute per run). Rate limiting is **enabled by default** with conservative settings:
- 500ms minimum interval between requests
- Automatic retry with exponential backoff on 429 errors

```elixir
# Custom rate limit settings
{:ok, logger} = Logging.create_logger(:wandb,
  project: "my-project",
  rate_limit: [min_interval_ms: 1000, max_retries: 5]
)

# Disable rate limiting (not recommended for free tier)
{:ok, logger} = Logging.create_logger(:wandb,
  project: "my-project",
  rate_limit: false
)
```

### Neptune.ai Integration

Full integration with [Neptune.ai](https://neptune.ai) for experiment tracking:

```elixir
# Setup:
# export NEPTUNE_API_TOKEN="your-api-token"
# export NEPTUNE_PROJECT="workspace/project-name"

{:ok, logger} = Logging.create_logger(:neptune,
  api_token: System.get_env("NEPTUNE_API_TOKEN"),
  project: System.get_env("NEPTUNE_PROJECT")
)

# Get run URL
url = Logging.get_url(logger)
# => "https://app.neptune.ai/workspace/project-name/e/RUN-1"

# Same logging API as other backends
Logging.log_hparams(logger, %{model: "deepseek-v3", batch_size: 64})
Logging.log_metrics(logger, step, %{loss: 0.3, grad_norm: 1.2})
Logging.close(logger)
```

**Rate Limiting**: Enabled by default with 200ms minimum interval. Configure the same way as W&B.

### Rate Limit Configuration

Both W&B and Neptune loggers support the following rate limit options:

| Option | Default (W&B) | Default (Neptune) | Description |
|--------|---------------|-------------------|-------------|
| `min_interval_ms` | 500 | 200 | Minimum ms between requests |
| `max_retries` | 3 | 3 | Retry attempts on 429 |
| `base_backoff_ms` | 1000 | 1000 | Initial backoff duration |
| `max_backoff_ms` | 30000 | 30000 | Maximum backoff cap |

## Evaluation & Scoring

Pluggable scoring system for model evaluation:

```elixir
alias CrucibleTrain.Eval.{Scoring, BatchRunner}

# Score individual outputs
Scoring.score(:exact_match, "Paris", "Paris")     # => 1.0
Scoring.score(:contains, "The answer is 42", "42") # => 1.0

# Streaming batch evaluation
results =
  samples
  |> BatchRunner.stream_evaluate(config, chunk_size: 25)
  |> Enum.to_list()

metrics = BatchRunner.aggregate_metrics(results)
# => %{mean_score: 0.85, total: 100, correct: 85}
```

## Learning Rate Scheduling

Flexible LR schedules with warmup support:

```elixir
alias CrucibleTrain.Supervised.Config

# Cosine annealing with warmup
config = %Config{
  learning_rate: 1.0e-4,
  lr_schedule: {:warmup, 100, :cosine}
}

# Available schedules: :constant, :linear, :cosine
# Warmup: {:warmup, warmup_steps, base_schedule}
```

## Examples

See the [`examples/`](examples/) directory for runnable demos:

```bash
# Run all local examples
./examples/run_all.sh

# Run individual examples
mix run --no-start examples/json_logger_example.exs
mix run --no-start examples/wandb_logger_example.exs
mix run --no-start examples/scoring_example.exs
```

| Example | Description |
|---------|-------------|
| `json_logger_example.exs` | Local JSONL logging |
| `pretty_print_logger_example.exs` | Console table output |
| `multiplex_logger_example.exs` | Multiple backends |
| `wandb_logger_example.exs` | Weights & Biases |
| `neptune_logger_example.exs` | Neptune.ai |
| `scoring_example.exs` | Evaluation scoring |
| `batch_runner_example.exs` | Batch evaluation |
| `lr_scheduling_example.exs` | LR schedules |

See [`examples/README.md`](examples/README.md) for setup instructions for cloud services.

## Documentation

Full documentation available at [HexDocs](https://hexdocs.pm/crucible_train).

## License

MIT License - see [LICENSE](LICENSE) for details.
