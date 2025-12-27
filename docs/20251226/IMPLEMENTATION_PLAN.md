# CrucibleTrain Implementation Plan

**Date:** 2025-12-26
**Current Version:** 0.1.1
**Status:** Initial Assessment

---

## 1. Executive Summary

CrucibleTrain is a comprehensive ML training infrastructure library for Elixir/BEAM providing:

- **Training Paradigms:** Supervised, RL (REINFORCE-style), DPO, and on-policy distillation
- **Renderer System:** Tokenization and message formatting for major model families (Llama3, Qwen3, DeepSeek, Kimi, GPT-OSS)
- **Ports & Adapters:** Pluggable backends for training, inference, storage, and hub operations
- **Logging System:** Multiplexed logging with JSON and pretty-print backends
- **Evaluation Framework:** Basic NLL evaluator and simple scoring (exact match, contains, case-insensitive)
- **Crucible Integration:** Pipeline stages for supervised, RL, DPO, and distillation training

### Key Findings

1. **W&B/Neptune Logging:** NOT IMPLEMENTED - only JsonLogger and PrettyPrintLogger exist
2. **Model Info Utilities:** MISSING - no hyperparameter introspection or model metadata utilities
3. **Evaluation Framework:** BASIC - limited scoring methods, no semantic similarity or embedding-based metrics
4. **Tinker/Python Parity:** PARTIAL - core training loops exist but missing advanced features

---

## 2. Current Implementation State

### 2.1 Ports & Adapters Architecture

| Port | Behaviour | Noop Adapter | Production Adapter |
|------|-----------|--------------|-------------------|
| `TrainingClient` | 7 callbacks | Yes | None |
| `LLMClient` | 1 callback | Yes | None |
| `HubClient` | 3 callbacks | Yes | None |
| `BlobStore` | 4 callbacks | Yes | None |
| `DatasetStore` | 7 callbacks | Yes | None |
| `EmbeddingClient` | 1 callback | Yes | None |
| `VectorStore` | 6 callbacks | Yes | None |

**Gap:** No production adapters exist. The library defines behaviours but requires external implementations.

### 2.2 Logging System

**Implemented:**
- `CrucibleTrain.Logging.Logger` - Behaviour with 4 required + 3 optional callbacks
- `CrucibleTrain.Logging.JsonLogger` - JSONL file logging with metrics.jsonl and config.json
- `CrucibleTrain.Logging.PrettyPrintLogger` - Console table output via TableRex
- `CrucibleTrain.Logging.MultiplexLogger` - Forwards to multiple backends
- `CrucibleTrain.Logging.DumpConfig` - Struct serialization helpers

**Missing:**
- W&B (Weights & Biases) logger backend
- Neptune logger backend
- TensorBoard logger backend
- Remote logging capabilities
- Experiment run management (run IDs, artifacts, tags)

### 2.3 Evaluation Framework

**Implemented:**
- `CrucibleTrain.Eval.Evaluator` - Single callback behaviour
- `CrucibleTrain.Eval.Evaluators` - TrainingClientEvaluator and SamplingClientEvaluator behaviours
- `CrucibleTrain.Eval.Runner` - Basic evaluation orchestrator with scoring
- `CrucibleTrain.Supervised.NLLEvaluator` - Negative log-likelihood evaluation
- `CrucibleTrain.Preference.ComparisonEvaluator` - Simple accuracy for preference labels

**Scoring Methods (in Eval.Runner):**
- `:exact_match` - String equality after trim
- `:contains` - Substring check
- `:case_insensitive` - Case-insensitive equality

**Missing:**
- Semantic similarity scoring (embedding-based)
- BLEU/ROUGE/F1 metrics
- Perplexity calculation utilities
- Batch evaluation with streaming
- Evaluation result persistence
- Metrics aggregation across runs

### 2.4 Training Loops

**Implemented:**
- `CrucibleTrain.Supervised.Train` - Full supervised training loop with LR scheduling
- `CrucibleTrain.RL.Train` - RL training with rollouts and advantage computation
- `CrucibleTrain.Preference.TrainDPO` - DPO wrapper around supervised training
- `CrucibleTrain.Distillation.TrainOnPolicy` - On-policy distillation loop

**Features:**
- Configurable learning rate schedules (linear, cosine, constant)
- Adam optimizer parameters (beta1, beta2, eps)
- Epoch-based training with batch iteration
- Async checkpoint saving
- Logging integration

**Missing:**
- Gradient accumulation
- Mixed precision training flags
- Early stopping
- Learning rate warmup
- Evaluation during training
- Model selection based on validation loss

### 2.5 Renderer System

**Implemented (6 model families):**
- Llama3 (with Instruct variant)
- Qwen3 (with Instruct and DisableThinking variants)
- DeepSeekV3 (with DisableThinking variant)
- KimiK2
- GPT-OSS (multiple reasoning effort levels)
- RoleColon (simple format)

**Features:**
- Message rendering with role tokens
- Tool call support
- Multimodal content (text + image)
- TrainOnWhat weight assignment
- Generation prompt building
- Stop sequence configuration

### 2.6 Type System

**Core Types:**
- `Datum` - Training unit with ModelInput and loss_fn_inputs
- `ModelInput` - Sequence of EncodedTextChunk and ImageChunk
- `TensorData` - Typed tensor wrapper with shape info
- `TokensWithLogprobs` - Completion result with optional logprobs

### 2.7 Utilities

**Implemented:**
- `LRScheduling` - Learning rate schedule computation
- `MiscUtils` - Timing, safe zip, list splitting
- `Logtree` - Structured logging with scopes and tables
- `PRNG.PCG64` - NumPy-compatible PRNG for reproducibility
- `Parity` - Python interop helpers
- `Trace` - Debug tracing utilities

---

## 3. Gap Analysis: Python tinker-cookbook Parity

Based on typical Python ML training infrastructure (like tinker-cookbook), these features are missing:

### 3.1 Logging & Experiment Tracking (HIGH PRIORITY)

| Feature | Python | Elixir | Gap |
|---------|--------|--------|-----|
| W&B integration | Yes | No | **CRITICAL** |
| Neptune integration | Yes | No | Important |
| TensorBoard | Yes | No | Nice-to-have |
| Run management | Yes | Partial | Needs work |
| Artifact tracking | Yes | No | **IMPORTANT** |
| Hyperparameter logging | Yes | Yes | Done |
| Metric charting | Yes | No | W&B provides |

### 3.2 Model Utilities (MEDIUM PRIORITY)

| Feature | Python | Elixir | Gap |
|---------|--------|--------|-----|
| Model info (params, layers) | Yes | No | **NEEDED** |
| Config serialization | Yes | Partial | DumpConfig exists |
| Tokenizer introspection | Yes | No | Via renderer |
| Memory estimation | Yes | No | Nice-to-have |

### 3.3 Evaluation (MEDIUM PRIORITY)

| Feature | Python | Elixir | Gap |
|---------|--------|--------|-----|
| BLEU/ROUGE | Yes | No | Use crucible_datasets |
| Semantic similarity | Yes | No | **NEEDED** |
| Perplexity | Yes | Partial | NLL exists |
| Batch streaming eval | Yes | No | **NEEDED** |
| Eval persistence | Yes | No | **NEEDED** |

### 3.4 Training Features (LOWER PRIORITY)

| Feature | Python | Elixir | Gap |
|---------|--------|--------|-----|
| Gradient accumulation | Yes | No | Backend-dependent |
| Mixed precision | Yes | No | Backend-dependent |
| Early stopping | Yes | No | **EASY ADD** |
| LR warmup | Yes | No | **EASY ADD** |
| Eval during training | Yes | Partial | save_every/eval_every exist |

---

## 4. W&B/Neptune Integration Strategy

### 4.1 Recommended Approach: HTTP API

**Rationale:**
- W&B and Neptune both have REST APIs
- No Python dependency required
- Can use Elixir's built-in HTTP clients (Req, Finch, Mint)
- Aligns with ports/adapters architecture

**Implementation Plan:**

1. **Create `CrucibleTrain.Logging.WandbLogger`**
   - Implements `Logger` behaviour
   - Uses HTTP API for metrics, configs, artifacts
   - Manages run lifecycle (init, log, sync, finish)

2. **Create `CrucibleTrain.Logging.NeptuneLogger`**
   - Similar structure to WandbLogger
   - Neptune-specific API handling

3. **Add to MultiplexLogger usage**
   - Easy integration with existing logging

### 4.2 Alternative: Snakebridge (NOT RECOMMENDED)

Snakebridge would allow calling Python W&B/Neptune directly, but:
- Adds Python runtime dependency
- Increases complexity
- May have performance overhead
- Not aligned with BEAM philosophy

### 4.3 Minimum Viable W&B Logger

```elixir
defmodule CrucibleTrain.Logging.WandbLogger do
  @behaviour CrucibleTrain.Logging.Logger

  # Required callbacks
  def init(opts)          # Create run via API
  def log_metrics(...)    # POST /api/v1/runs/{run_id}/history
  def log_hparams(...)    # POST /api/v1/runs/{run_id}/config
  def close(...)          # Finish run

  # Optional callbacks
  def sync(...)           # Flush pending logs
  def get_url(...)        # Return run URL
  def log_long_text(...)  # Log as artifact
end
```

---

## 5. Model Info Utilities

### 5.1 Proposed Module: `CrucibleTrain.ModelInfo`

```elixir
defmodule CrucibleTrain.ModelInfo do
  @type model_config :: %{
    model_name: String.t(),
    vocab_size: pos_integer(),
    hidden_size: pos_integer(),
    num_layers: pos_integer(),
    num_heads: pos_integer(),
    max_seq_length: pos_integer(),
    architecture: String.t()
  }

  @callback get_config(term()) :: {:ok, model_config()} | {:error, term()}
  @callback count_parameters(term()) :: {:ok, pos_integer()} | {:error, term()}
  @callback get_special_tokens(term()) :: {:ok, map()} | {:error, term()}
end
```

### 5.2 Integration Points

- Add to `TrainingClient` callbacks for model introspection
- Use in logging for automatic hyperparameter capture
- Renderer can expose tokenizer metadata

---

## 6. Evaluation Framework Improvements

### 6.1 Scoring Methods to Add

```elixir
defmodule CrucibleTrain.Eval.Scoring do
  @callback score(output :: String.t(), target :: String.t(), opts :: keyword()) :: float()

  # Implementations:
  # - ExactMatch
  # - Contains
  # - CaseInsensitive
  # - SemanticSimilarity (requires embedding client)
  # - BLEU (can delegate to crucible_datasets)
  # - ROUGE (can delegate to crucible_datasets)
  # - F1Token (token-level)
end
```

### 6.2 Batch Evaluation

```elixir
defmodule CrucibleTrain.Eval.BatchRunner do
  @doc "Stream evaluation over large datasets"
  def stream_evaluate(samples, config, chunk_size \\ 100)

  @doc "Persist results to JSONL"
  def persist_results(results, path)

  @doc "Aggregate metrics across batches"
  def aggregate_metrics(batch_results)
end
```

---

## 7. Prioritized Action Items

### Priority 1: Critical (W&B Integration)

1. **Add HTTP client dependency** (Req or Finch)
2. **Implement `WandbLogger`** with core callbacks
3. **Add run management** (create, update, finish)
4. **Add artifact upload** for checkpoints
5. **Tests with mock HTTP**

### Priority 2: High (Evaluation)

1. **Add `SemanticSimilarityScorer`** using EmbeddingClient port
2. **Add `BatchRunner`** for streaming evaluation
3. **Add result persistence** to JSONL
4. **Integrate BLEU/ROUGE** from crucible_datasets

### Priority 3: Medium (Training Improvements)

1. **Add LR warmup** to LRScheduling
2. **Add early stopping** callback system
3. **Add eval_during_training** hook
4. **Add gradient accumulation** flag to configs

### Priority 4: Lower (Model Info)

1. **Define `ModelInfo` behaviour**
2. **Add to TrainingClient** as optional callbacks
3. **Add tokenizer introspection** helpers

---

## 8. Dependency Considerations

### Current Dependencies (from mix.exs)

```elixir
{:chz_ex, "~> 0.1.2"},
{:jason, "~> 1.4"},
{:telemetry, "~> 1.2"},
{:table_rex, "~> 4.0"},
{:ecto_sql, "~> 3.11"},
{:crucible_framework, "~> 0.4.0"},
{:crucible_ir, "~> 0.2.0"},
```

### Recommended Additions

```elixir
{:req, "~> 0.4"},           # HTTP client for W&B/Neptune APIs
{:finch, "~> 0.18"},        # Optional: connection pooling
```

### Optional for Evaluation

```elixir
{:crucible_datasets, "~> X.X.X"},  # BLEU/ROUGE metrics
```

---

## 9. Testing Strategy

### Existing Test Coverage

Tests exist for:
- Types (Datum, ModelInput, TensorData, TokensWithLogprobs)
- Renderers (all implementations)
- Supervised training
- RL training
- Completers
- Preference types
- Distillation datasets

### New Tests Needed

1. **WandbLogger tests** with mocked HTTP
2. **NeptuneLogger tests** with mocked HTTP
3. **SemanticSimilarityScorer tests** with mock embeddings
4. **BatchRunner tests** for streaming
5. **LR warmup tests**
6. **Early stopping tests**

---

## 10. Implementation Timeline

| Phase | Scope | Estimated Effort |
|-------|-------|-----------------|
| Phase 1 | W&B Logger MVP | 2-3 days |
| Phase 2 | Neptune Logger | 1-2 days |
| Phase 3 | Evaluation improvements | 2-3 days |
| Phase 4 | Training enhancements | 1-2 days |
| Phase 5 | Model info utilities | 1 day |

**Total:** 7-11 days for comprehensive implementation

---

## 11. File Summary

### Files Reviewed

**Core Module:**
- `/lib/crucible_train/crucible_train.ex` - Main API delegations
- `/lib/crucible_train/application.ex` - OTP application

**Ports (7 behaviours):**
- `/lib/crucible_train/ports/ports.ex` - Composition root
- `/lib/crucible_train/ports/training_client.ex`
- `/lib/crucible_train/ports/llm_client.ex`
- `/lib/crucible_train/ports/hub_client.ex`
- `/lib/crucible_train/ports/blob_store.ex`
- `/lib/crucible_train/ports/dataset_store.ex`
- `/lib/crucible_train/ports/embedding_client.ex`
- `/lib/crucible_train/ports/vector_store.ex`
- `/lib/crucible_train/ports/error.ex`

**Adapters (7 noop implementations):**
- `/lib/crucible_train/adapters/noop/training_client.ex`
- `/lib/crucible_train/adapters/noop/llm_client.ex`
- `/lib/crucible_train/adapters/noop/hub_client.ex`
- `/lib/crucible_train/adapters/noop/blob_store.ex`
- `/lib/crucible_train/adapters/noop/dataset_store.ex`
- `/lib/crucible_train/adapters/noop/embedding_client.ex`
- `/lib/crucible_train/adapters/noop/vector_store.ex`

**Logging:**
- `/lib/crucible_train/logging.ex`
- `/lib/crucible_train/logging/logger.ex`
- `/lib/crucible_train/logging/json_logger.ex`
- `/lib/crucible_train/logging/pretty_print_logger.ex`
- `/lib/crucible_train/logging/multiplex_logger.ex`
- `/lib/crucible_train/logging/dump_config.ex`

**Evaluation:**
- `/lib/crucible_train/eval/evaluator.ex`
- `/lib/crucible_train/eval/evaluators.ex`
- `/lib/crucible_train/eval/runner.ex`
- `/lib/crucible_train/supervised/nll_evaluator.ex`
- `/lib/crucible_train/preference/comparison_evaluator.ex`

**Training:**
- `/lib/crucible_train/supervised/train.ex`
- `/lib/crucible_train/supervised/config.ex`
- `/lib/crucible_train/supervised/dataset.ex`
- `/lib/crucible_train/supervised/common.ex`
- `/lib/crucible_train/rl/train.ex`
- `/lib/crucible_train/rl/env.ex`
- `/lib/crucible_train/rl/env_group_builder.ex`
- `/lib/crucible_train/rl/rollouts.ex`
- `/lib/crucible_train/rl/data_processing.ex`
- `/lib/crucible_train/rl/metrics.ex`
- `/lib/crucible_train/rl/types.ex`
- `/lib/crucible_train/rl/rl_dataset.ex`
- `/lib/crucible_train/rl/problem_env.ex`
- `/lib/crucible_train/preference/train_dpo.ex`
- `/lib/crucible_train/preference/dpo_datasets.ex`
- `/lib/crucible_train/preference/types.ex`
- `/lib/crucible_train/preference/preference_datasets.ex`
- `/lib/crucible_train/distillation/train_on_policy.ex`
- `/lib/crucible_train/distillation/datasets.ex`

**Stages:**
- `/lib/crucible_train/stages/supervised_train.ex`
- `/lib/crucible_train/stages/rl_train.ex`
- `/lib/crucible_train/stages/dpo_train.ex`
- `/lib/crucible_train/stages/distillation.ex`

**Types:**
- `/lib/crucible_train/types.ex`
- `/lib/crucible_train/types/datum.ex`
- `/lib/crucible_train/types/model_input.ex`
- `/lib/crucible_train/types/tensor_data.ex`
- `/lib/crucible_train/types/tokens_with_logprobs.ex`

**Renderers:**
- `/lib/crucible_train/renderers/renderer.ex`
- `/lib/crucible_train/renderers/registry.ex`
- `/lib/crucible_train/renderers/types.ex`
- `/lib/crucible_train/renderers/train_on_what.ex`
- `/lib/crucible_train/renderers/helpers.ex`
- `/lib/crucible_train/renderers/tool_calls.ex`
- `/lib/crucible_train/renderers/vision.ex`
- `/lib/crucible_train/renderers/llama3.ex`
- `/lib/crucible_train/renderers/qwen3.ex`
- `/lib/crucible_train/renderers/deepseek_v3.ex`
- `/lib/crucible_train/renderers/kimi_k2.ex`
- `/lib/crucible_train/renderers/gpt_oss.ex`
- `/lib/crucible_train/renderers/role_colon.ex`
- `/lib/crucible_train/renderers/implementations/*.ex` (6 files)

**Completers:**
- `/lib/crucible_train/completers/message_completer.ex`
- `/lib/crucible_train/completers/token_completer.ex`
- `/lib/crucible_train/completers/mock_completer.ex`

**Utilities:**
- `/lib/crucible_train/utils/lr_scheduling.ex`
- `/lib/crucible_train/utils/misc_utils.ex`
- `/lib/crucible_train/utils/logtree.ex`
- `/lib/crucible_train/utils/logtree_formatters.ex`
- `/lib/crucible_train/utils/parity.ex`
- `/lib/crucible_train/utils/trace.ex`
- `/lib/crucible_train/utils/prng/pcg64.ex`
- `/lib/crucible_train/utils/prng/seed_sequence.ex`

**Checkpoint:**
- `/lib/crucible_train/checkpoint/checkpoint.ex`

---

## 12. Conclusion

CrucibleTrain has a solid foundation with well-designed ports/adapters architecture and comprehensive training loop implementations. The primary gaps are:

1. **W&B/Neptune logging** - Critical for production ML workflows
2. **Advanced evaluation metrics** - Needed for comprehensive model assessment
3. **Model introspection utilities** - Helpful for debugging and monitoring

The recommended approach is HTTP-based integration for external services, maintaining Elixir purity while enabling full ecosystem access.
