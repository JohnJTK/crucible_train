# CrucibleTrain Examples

This directory contains runnable examples demonstrating CrucibleTrain's integrations.

## Quick Start

```bash
# Install dependencies
mix deps.get

# Run any example (--no-start avoids starting apps that require external services)
mix run --no-start examples/<example_name>.exs
```

## Examples Overview

| Example | Description | External Service |
|---------|-------------|------------------|
| `json_logger_example.exs` | Local JSONL logging | None |
| `pretty_print_logger_example.exs` | Console table output | None |
| `multiplex_logger_example.exs` | Multiple logging backends | None |
| `wandb_logger_example.exs` | Weights & Biases integration | W&B |
| `neptune_logger_example.exs` | Neptune.ai integration | Neptune |
| `scoring_example.exs` | Evaluation scoring functions | None |
| `batch_runner_example.exs` | Streaming batch evaluation | None |
| `lr_scheduling_example.exs` | Learning rate schedules | None |

## Service Setup Instructions

### Weights & Biases (W&B)

[Weights & Biases](https://wandb.ai) is a popular ML experiment tracking platform.

#### Account Setup

1. **Create an account**: Go to [wandb.ai/site](https://wandb.ai/site) and sign up
2. **Get your API key**: Navigate to [wandb.ai/authorize](https://wandb.ai/authorize)
3. **Copy your API key** (it looks like `wandb-xxxxxxxxxxxx`)

#### Environment Configuration

```bash
# Required
export WANDB_API_KEY="your-api-key-here"

# Optional: specify team/user (uses default if not set)
export WANDB_ENTITY="your-team-or-username"

# Optional: specify project (defaults to "crucible-train-demo")
export WANDB_PROJECT="my-project-name"
```

#### Run the Example

```bash
mix run examples/wandb_logger_example.exs
```

#### Programmatic Usage

```elixir
alias CrucibleTrain.Logging

{:ok, logger} = Logging.create_logger(:wandb,
  api_key: System.get_env("WANDB_API_KEY"),
  project: "my-project",
  entity: "my-team",       # optional
  run_name: "experiment-1" # optional
)

# Log hyperparameters
Logging.log_hparams(logger, %{learning_rate: 1.0e-4, batch_size: 32})

# Log metrics
Logging.log_metrics(logger, step, %{loss: 0.5, accuracy: 0.9})

# Get run URL
url = Logging.get_url(logger)

# Close when done
Logging.close(logger)
```

---

### Neptune.ai

[Neptune.ai](https://neptune.ai) is an ML metadata store for experiment tracking.

#### Account Setup

1. **Create an account**: Go to [neptune.ai](https://neptune.ai) and sign up
2. **Create a project**:
   - Click "New project" in the Neptune UI
   - Note the project path: `workspace-name/project-name`
3. **Get your API token**:
   - Click your user avatar (top right)
   - Select "Get your API token"
   - Copy the token

#### Environment Configuration

```bash
# Required
export NEPTUNE_API_TOKEN="your-api-token-here"
export NEPTUNE_PROJECT="workspace/project-name"
```

#### Run the Example

```bash
mix run examples/neptune_logger_example.exs
```

#### Programmatic Usage

```elixir
alias CrucibleTrain.Logging

{:ok, logger} = Logging.create_logger(:neptune,
  api_token: System.get_env("NEPTUNE_API_TOKEN"),
  project: "workspace/project-name",
  run_name: "experiment-1"  # optional
)

# Log hyperparameters
Logging.log_hparams(logger, %{model: "llama-3.1", epochs: 10})

# Log metrics
Logging.log_metrics(logger, step, %{loss: 0.3, perplexity: 1.35})

# Get run URL
url = Logging.get_url(logger)

# Close when done
Logging.close(logger)
```

---

## Local Examples (No Setup Required)

### JSON Logger

Logs metrics and hyperparameters to local JSONL files.

```bash
mix run examples/json_logger_example.exs
```

Output files:
- `metrics.jsonl` - One JSON object per line, each with step and metrics
- `config.json` - Hyperparameters as formatted JSON
- `<key>.txt` - Long-form text logs

### PrettyPrint Logger

Displays metrics as formatted console tables. Useful for development.

```bash
mix run examples/pretty_print_logger_example.exs
```

### Multiplex Logger

Logs to multiple backends simultaneously. Combine local + cloud logging:

```bash
mix run examples/multiplex_logger_example.exs
```

```elixir
# Example: Log to JSON files AND W&B
alias CrucibleTrain.Logging.{JsonLogger, WandbLogger}

{:ok, logger} = Logging.create_logger(:multiplex, loggers: [
  {JsonLogger, [log_dir: "./logs"]},
  {WandbLogger, [api_key: api_key, project: "my-project"]}
])
```

### Scoring Functions

Demonstrates the pluggable scoring system:

```bash
mix run examples/scoring_example.exs
```

Available scorers:
- `:exact_match` - Exact string match (after trimming)
- `:contains` - Substring containment
- `:semantic_similarity` - Cosine similarity via embeddings (requires embedding client)

### Batch Runner

Streaming batch evaluation with result persistence:

```bash
mix run examples/batch_runner_example.exs
```

### Learning Rate Scheduling

Demonstrates LR schedules with warmup:

```bash
mix run examples/lr_scheduling_example.exs
```

Available schedules:
- `:constant` - No decay
- `:linear` - Linear decay to 0
- `:cosine` - Cosine annealing
- `{:warmup, steps, schedule}` - Linear warmup followed by schedule

---

## Running All Examples

Use the provided script to run all examples:

```bash
# Run local examples only (no API keys required)
./examples/run_all.sh

# Run all examples including cloud services
./examples/run_all.sh --all
```

---

## Troubleshooting

### W&B Issues

| Error | Solution |
|-------|----------|
| `{:error, :missing_api_key}` | Set `WANDB_API_KEY` environment variable |
| `{:error, {:http_error, 401, _}}` | Invalid API key - regenerate at wandb.ai/authorize |
| `{:error, {:http_error, 404, _}}` | Project doesn't exist - it will be auto-created on first run |

### Neptune Issues

| Error | Solution |
|-------|----------|
| `{:error, :missing_api_token}` | Set `NEPTUNE_API_TOKEN` environment variable |
| `{:error, :missing_project}` | Set `NEPTUNE_PROJECT` in format `workspace/project` |
| `{:error, {:http_error, 401, _}}` | Invalid token - get new one from Neptune UI |
| `{:error, {:http_error, 404, _}}` | Project not found - create it in Neptune UI first |
