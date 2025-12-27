# CrucibleTrain Implementation Prompt

**For AI Agent Implementation**
**Date:** 2025-12-26

---

## Mission

You are implementing missing features in the CrucibleTrain Elixir library for ML training infrastructure. Your task is to add W&B logging, Neptune logging, improved evaluation framework, and model info utilities while maintaining TDD practices and code quality standards.

---

## Required Reading (READ ALL BEFORE STARTING)

You MUST read and understand these files before implementing anything:

### Configuration Files
- `/home/home/p/g/North-Shore-AI/crucible_train/mix.exs` - Dependencies and project config
- `/home/home/p/g/North-Shore-AI/crucible_train/README.md` - Package documentation
- `/home/home/p/g/North-Shore-AI/crucible_train/CHANGELOG.md` - Version history

### Core Architecture
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/crucible_train.ex` - Main API module
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/application.ex` - OTP application
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/ports/ports.ex` - Ports composition root

### Logging System (Critical for W&B/Neptune implementation)
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/logging.ex` - Logging helpers
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/logging/logger.ex` - Logger behaviour
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/logging/json_logger.ex` - JSON implementation
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/logging/pretty_print_logger.ex` - Console implementation
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/logging/multiplex_logger.ex` - Multi-backend
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/logging/dump_config.ex` - Serialization

### Evaluation Framework (Critical for evaluation improvements)
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/eval/evaluator.ex` - Evaluator behaviour
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/eval/evaluators.ex` - Evaluator types
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/eval/runner.ex` - Eval orchestrator
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/supervised/nll_evaluator.ex` - NLL evaluator
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/preference/comparison_evaluator.ex` - Comparison evaluator

### Ports (for understanding adapter pattern)
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/ports/training_client.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/ports/llm_client.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/ports/hub_client.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/ports/blob_store.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/ports/dataset_store.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/ports/embedding_client.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/ports/vector_store.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/ports/error.ex`

### Existing Adapters (for pattern reference)
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/adapters/noop/training_client.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/adapters/noop/llm_client.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/adapters/noop/blob_store.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/adapters/noop/dataset_store.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/adapters/noop/hub_client.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/adapters/noop/embedding_client.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/adapters/noop/vector_store.ex`

### Training Loops (context for evaluation integration)
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/supervised/train.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/supervised/config.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/supervised/dataset.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/supervised/common.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/rl/train.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/preference/train_dpo.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/distillation/train_on_policy.ex`

### Types (for understanding data structures)
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/types.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/types/datum.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/types/model_input.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/types/tensor_data.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/types/tokens_with_logprobs.ex`

### Utilities
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/utils/lr_scheduling.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/utils/misc_utils.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/checkpoint/checkpoint.ex`

### Renderers (for tokenizer context)
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/renderers/renderer.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/renderers/registry.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/renderers/types.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/renderers/helpers.ex`

### Existing Tests (for test patterns)
- `/home/home/p/g/North-Shore-AI/crucible_train/test/test_helper.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/types/datum_test.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/types/model_input_test.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/types/tensor_data_test.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/types/tokens_with_logprobs_test.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/renderers/renderer_test.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/renderers/llama3_test.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/renderers/qwen3_test.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/renderers/deepseek_v3_test.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/renderers/kimi_k2_test.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/renderers/gpt_oss_test.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/renderers/role_colon_test.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/renderers/train_on_what_test.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/renderers/tool_calls_test.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/renderers/helpers_test.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/renderers/types_test.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/renderers/eot_parsing_test.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/supervised/train_test.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/supervised/dataset_test.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/supervised/common_test.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/rl/train_test.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/rl/types_test.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/preference/types_test.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/distillation/datasets_test.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/completers/mock_completer_test.exs`

### Test Support Files
- `/home/home/p/g/North-Shore-AI/crucible_train/test/support/mock_tokenizer.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/support/mock_tokenizer_special.ex`

---

## Project Context

CrucibleTrain is part of the North-Shore-AI monorepo ecosystem:

- **crucible_framework** - ML experimentation orchestration
- **crucible_ir** - Intermediate representation for ML pipelines
- **crucible_bench** - Statistical testing
- **crucible_datasets** - Dataset management and evaluation metrics
- **crucible_telemetry** - Instrumentation and metrics streaming

CrucibleTrain specifically handles:

1. **Training Loops:** Supervised, RL, DPO, distillation
2. **Renderers:** Message-to-token transformation for model families
3. **Ports & Adapters:** Pluggable backends via behaviour pattern
4. **Logging:** Multiplexed ML logging infrastructure
5. **Evaluation:** Model evaluation and scoring

---

## Implementation Tasks (TDD Approach)

For EACH task:
1. Write tests FIRST
2. Implement code to pass tests
3. Refactor if needed
4. Run `mix test`, `mix format`, `mix credo --strict`, `mix dialyzer`
5. Fix ALL issues before proceeding

### Task 1: Add HTTP Client Dependency

**File to modify:** `/home/home/p/g/North-Shore-AI/crucible_train/mix.exs`

Add Req HTTP client:
```elixir
{:req, "~> 0.5"},
```

Run `mix deps.get` after modification.

### Task 2: Implement W&B Logger

**Files to create:**
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/logging/wandb_logger.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/logging/wandb_logger_test.exs`

**Implementation requirements:**

```elixir
defmodule CrucibleTrain.Logging.WandbLogger do
  @moduledoc """
  Weights & Biases logger backend using HTTP API.

  ## Configuration

  Requires the following options on init:
  - `:api_key` - W&B API key (or set WANDB_API_KEY env var)
  - `:project` - Project name
  - `:entity` - Optional team/user name

  ## Example

      {:ok, logger} = WandbLogger.init(
        api_key: System.get_env("WANDB_API_KEY"),
        project: "my-project",
        entity: "my-team",
        run_name: "experiment-1"
      )
  """

  @behaviour CrucibleTrain.Logging.Logger

  defstruct [:api_key, :project, :entity, :run_id, :run_name, :base_url]

  @type t :: %__MODULE__{
    api_key: String.t(),
    project: String.t(),
    entity: String.t() | nil,
    run_id: String.t() | nil,
    run_name: String.t() | nil,
    base_url: String.t()
  }

  @base_url "https://api.wandb.ai"

  # Required callbacks
  @impl true
  def init(opts)
  # - Validate api_key (from opts or WANDB_API_KEY env)
  # - Create run via POST to API
  # - Return {:ok, state} or {:error, reason}

  @impl true
  def log_metrics(state, step, metrics)
  # - POST metrics to /api/v1/runs/{run_id}/history
  # - Handle API errors gracefully

  @impl true
  def log_hparams(state, hparams)
  # - POST config to /api/v1/runs/{run_id}/config

  @impl true
  def close(state)
  # - Mark run as finished

  # Optional callbacks
  @impl true
  def sync(state)
  # - Flush any pending data

  @impl true
  def get_url(state)
  # - Return run URL: "https://wandb.ai/{entity}/{project}/runs/{run_id}"

  @impl true
  def log_long_text(state, key, text)
  # - Log as artifact or summary
end
```

**Test requirements:**
- Mock HTTP responses using Mox or Bypass
- Test init with valid/invalid config
- Test log_metrics with various metric types
- Test log_hparams with nested config
- Test close behavior
- Test get_url format
- Test error handling for API failures

### Task 3: Implement Neptune Logger

**Files to create:**
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/logging/neptune_logger.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/logging/neptune_logger_test.exs`

**Implementation requirements:**
Similar structure to WandbLogger but for Neptune.ai API.

```elixir
defmodule CrucibleTrain.Logging.NeptuneLogger do
  @moduledoc """
  Neptune.ai logger backend using HTTP API.

  ## Configuration

  - `:api_token` - Neptune API token
  - `:project` - Project qualified name (workspace/project)

  ## Example

      {:ok, logger} = NeptuneLogger.init(
        api_token: System.get_env("NEPTUNE_API_TOKEN"),
        project: "workspace/project-name"
      )
  """

  @behaviour CrucibleTrain.Logging.Logger

  @base_url "https://app.neptune.ai/api/leaderboard/v1"

  # Same callback structure as WandbLogger
end
```

### Task 4: Update Logging Module

**File to modify:** `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/logging.ex`

Add resolution for new logger types:

```elixir
defp resolve_logger_module(:wandb), do: WandbLogger
defp resolve_logger_module(:neptune), do: NeptuneLogger
```

### Task 5: Add Semantic Similarity Scorer

**Files to create:**
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/eval/scoring.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/eval/scorers/exact_match.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/eval/scorers/contains.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/eval/scorers/semantic_similarity.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/eval/scoring_test.exs`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/eval/scorers/semantic_similarity_test.exs`

**Implementation:**

```elixir
defmodule CrucibleTrain.Eval.Scoring do
  @moduledoc """
  Behaviour for scoring functions.
  """

  @callback score(output :: String.t(), target :: String.t(), opts :: keyword()) :: float()
  @callback name() :: String.t()

  @doc "Score using the specified method"
  @spec score(atom(), String.t(), String.t(), keyword()) :: float()
  def score(method, output, target, opts \\ [])
end

defmodule CrucibleTrain.Eval.Scorers.SemanticSimilarity do
  @moduledoc """
  Semantic similarity scorer using embeddings.
  """

  @behaviour CrucibleTrain.Eval.Scoring

  alias CrucibleTrain.Ports.EmbeddingClient

  @impl true
  def score(output, target, opts) do
    ports = Keyword.fetch!(opts, :ports)

    with {:ok, [output_emb]} <- EmbeddingClient.embed_texts(ports, [output]),
         {:ok, [target_emb]} <- EmbeddingClient.embed_texts(ports, [target]) do
      cosine_similarity(output_emb, target_emb)
    else
      {:error, _} -> 0.0
    end
  end

  @impl true
  def name, do: "semantic_similarity"

  defp cosine_similarity(a, b) do
    # Compute cosine similarity between two vectors
  end
end
```

### Task 6: Add Batch Evaluation Runner

**Files to create:**
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/eval/batch_runner.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/eval/batch_runner_test.exs`

**Implementation:**

```elixir
defmodule CrucibleTrain.Eval.BatchRunner do
  @moduledoc """
  Streaming batch evaluation runner.
  """

  require Logger

  @doc "Stream evaluation in chunks"
  @spec stream_evaluate([map()], map(), keyword()) :: Enumerable.t()
  def stream_evaluate(samples, config, opts \\ [])

  @doc "Persist results to JSONL file"
  @spec persist_results(Enumerable.t(), Path.t()) :: :ok | {:error, term()}
  def persist_results(results, path)

  @doc "Aggregate metrics from results"
  @spec aggregate_metrics([map()]) :: map()
  def aggregate_metrics(results)
end
```

### Task 7: Add LR Warmup

**File to modify:** `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/utils/lr_scheduling.ex`

Add warmup support:

```elixir
@type lr_schedule :: :linear | :cosine | :constant | {:warmup, non_neg_integer(), lr_schedule()}

def compute_schedule_lr_multiplier({:warmup, warmup_steps, schedule}, step, total_steps) do
  if step < warmup_steps do
    step / warmup_steps
  else
    adjusted_step = step - warmup_steps
    adjusted_total = total_steps - warmup_steps
    compute_schedule_lr_multiplier(schedule, adjusted_step, adjusted_total)
  end
end
```

**File to create:** `/home/home/p/g/North-Shore-AI/crucible_train/test/utils/lr_scheduling_test.exs`

### Task 8: Add Model Info Behaviour

**Files to create:**
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/model_info.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/test/model_info_test.exs`

**Implementation:**

```elixir
defmodule CrucibleTrain.ModelInfo do
  @moduledoc """
  Behaviour for model introspection.
  """

  @type model_config :: %{
    optional(:model_name) => String.t(),
    optional(:vocab_size) => pos_integer(),
    optional(:hidden_size) => pos_integer(),
    optional(:num_layers) => pos_integer(),
    optional(:num_heads) => pos_integer(),
    optional(:max_seq_length) => pos_integer(),
    optional(:architecture) => String.t()
  }

  @callback get_config(term()) :: {:ok, model_config()} | {:error, term()}
  @callback count_parameters(term()) :: {:ok, pos_integer()} | {:error, term()}
  @callback get_special_tokens(term()) :: {:ok, map()} | {:error, term()}

  @optional_callbacks [count_parameters: 1, get_special_tokens: 1]
end
```

---

## Version Bump Instructions

After all implementations are complete:

### 1. Update mix.exs

Change version from `"0.1.1"` to `"0.2.0"`:

```elixir
@version "0.2.0"
```

### 2. Update README.md

Change installation instruction from:
```elixir
{:crucible_train, "~> 0.1.1"}
```

To:
```elixir
{:crucible_train, "~> 0.2.0"}
```

### 3. Update CHANGELOG.md

Add new entry at the top:

```markdown
## 0.2.0 (2025-12-26)

### Added

- W&B (Weights & Biases) logger backend via HTTP API
- Neptune.ai logger backend via HTTP API
- Scoring behaviour with pluggable scorers
- SemanticSimilarity scorer using embeddings
- Batch evaluation runner with streaming support
- LR warmup support in learning rate scheduling
- ModelInfo behaviour for model introspection

### Changed

- Added `req` HTTP client dependency (~> 0.5)
- Updated logging module with wandb/neptune resolution
```

---

## Files to Create/Modify Summary

### New Files to Create

1. `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/logging/wandb_logger.ex`
2. `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/logging/neptune_logger.ex`
3. `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/eval/scoring.ex`
4. `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/eval/scorers/exact_match.ex`
5. `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/eval/scorers/contains.ex`
6. `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/eval/scorers/semantic_similarity.ex`
7. `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/eval/batch_runner.ex`
8. `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/model_info.ex`
9. `/home/home/p/g/North-Shore-AI/crucible_train/test/logging/wandb_logger_test.exs`
10. `/home/home/p/g/North-Shore-AI/crucible_train/test/logging/neptune_logger_test.exs`
11. `/home/home/p/g/North-Shore-AI/crucible_train/test/eval/scoring_test.exs`
12. `/home/home/p/g/North-Shore-AI/crucible_train/test/eval/scorers/semantic_similarity_test.exs`
13. `/home/home/p/g/North-Shore-AI/crucible_train/test/eval/batch_runner_test.exs`
14. `/home/home/p/g/North-Shore-AI/crucible_train/test/utils/lr_scheduling_test.exs`
15. `/home/home/p/g/North-Shore-AI/crucible_train/test/model_info_test.exs`

### Existing Files to Modify

1. `/home/home/p/g/North-Shore-AI/crucible_train/mix.exs` - Add req dependency, bump version
2. `/home/home/p/g/North-Shore-AI/crucible_train/README.md` - Update version
3. `/home/home/p/g/North-Shore-AI/crucible_train/CHANGELOG.md` - Add 0.2.0 entry
4. `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/logging.ex` - Add wandb/neptune resolution
5. `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/utils/lr_scheduling.ex` - Add warmup support

---

## Quality Requirements

Before considering any task complete, ensure:

### 1. All Tests Pass
```bash
mix test
```
Expected: 0 failures

### 2. No Compiler Warnings
```bash
mix compile --warnings-as-errors
```
Expected: No warnings

### 3. Code Formatting
```bash
mix format --check-formatted
```
Expected: All files formatted

### 4. Credo Strict Mode
```bash
mix credo --strict
```
Expected: No issues

### 5. Dialyzer
```bash
mix dialyzer
```
Expected: No errors

---

## Testing Guidelines

### Use Mox for HTTP Mocking

For W&B and Neptune tests, use Mox to mock HTTP responses:

```elixir
# In test_helper.exs
Mox.defmock(CrucibleTrain.HTTPMock, for: HTTPBehaviour)

# In tests
test "logs metrics to wandb" do
  expect(CrucibleTrain.HTTPMock, :post, fn url, body, headers ->
    assert url =~ "/api/v1/runs/"
    {:ok, %{status: 200, body: "{}"}}
  end)

  # ... test code
end
```

Alternatively, use Bypass for HTTP testing:

```elixir
setup do
  bypass = Bypass.open()
  {:ok, bypass: bypass}
end

test "logs metrics to wandb", %{bypass: bypass} do
  Bypass.expect_once(bypass, "POST", "/api/v1/runs/run-123/history", fn conn ->
    Plug.Conn.resp(conn, 200, "{}")
  end)

  # ... test with base_url: "http://localhost:#{bypass.port}"
end
```

### Test File Structure

Follow existing test patterns:

```elixir
defmodule CrucibleTrain.Logging.WandbLoggerTest do
  use ExUnit.Case, async: true

  alias CrucibleTrain.Logging.WandbLogger

  describe "init/1" do
    test "succeeds with valid configuration" do
      # ...
    end

    test "fails without api_key" do
      # ...
    end
  end

  describe "log_metrics/3" do
    test "posts metrics to API" do
      # ...
    end
  end

  # ... more tests
end
```

---

## Implementation Order

Complete tasks in this order:

1. **Task 1:** Add HTTP client dependency (prerequisite for others)
2. **Task 2:** Implement W&B Logger (highest priority)
3. **Task 3:** Implement Neptune Logger (similar pattern)
4. **Task 4:** Update Logging Module (integrate new loggers)
5. **Task 7:** Add LR Warmup (independent, quick win)
6. **Task 5:** Add Semantic Similarity Scorer
7. **Task 6:** Add Batch Evaluation Runner
8. **Task 8:** Add Model Info Behaviour
9. **Version Bump:** Update version numbers and changelog

---

## Notes

- Maintain backwards compatibility with existing Logger behaviour
- Use proper @moduledoc and @doc annotations
- Include typespecs for all public functions
- Follow Elixir naming conventions (snake_case for functions)
- Use pattern matching and guard clauses appropriately
- Handle errors gracefully with {:ok, result} | {:error, reason} tuples
- Add telemetry events for observability where appropriate

---

## Success Criteria

The implementation is complete when:

1. All new files are created with proper implementations
2. All existing files are updated correctly
3. `mix test` passes with 0 failures
4. `mix compile --warnings-as-errors` produces no warnings
5. `mix format --check-formatted` shows all files formatted
6. `mix credo --strict` reports no issues
7. `mix dialyzer` reports no errors
8. Version is bumped to 0.2.0
9. CHANGELOG.md has 2025-12-26 entry
10. README.md has updated version

Good luck!
