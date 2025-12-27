# IR to Training Specification (CrucibleTrain)

Date: 2025-12-26
Status: Draft
Owner: North-Shore-AI

## 1) Purpose

Define how `crucible_train` consumes `CrucibleIR.Training.Config` at the stage boundary while keeping the core training loops independent of IR. This enables a spec-driven pipeline (`run spec + run`) without coupling IR to execution.

## 2) Goals

- Allow `CrucibleTrain` stages to accept `%CrucibleIR.Training.Config{}` or a raw map.
- Normalize IR configs into `CrucibleTrain.*.Config` structs.
- Keep training loops free of IR dependencies.
- Make `crucible_ir` a real, used dependency in `crucible_train`.

## 3) Non-Goals

- Do not move execution logic into `crucible_ir`.
- Do not rewrite training loops or data types.
- Do not require IR for direct `CrucibleTrain.*.Train.main/1` usage.

## 4) Design Overview

### 4.1 New Normalization Module

Add a new module in `crucible_train`:

```
CrucibleTrain.IR.Normalize
```

Responsibilities:
- Accept input as `%CrucibleIR.Training.Config{}` or map.
- Resolve dataset/model refs when ports are available.
- Produce a `CrucibleTrain` config struct appropriate for the stage.

### 4.2 Stage Integration

Update stage modules to call the normalization layer:

- `CrucibleTrain.Stages.SupervisedTrain`
- `CrucibleTrain.Stages.RLTrain`
- `CrucibleTrain.Stages.DPOTrain`
- `CrucibleTrain.Stages.Distillation`

Stage options should accept:
- `training_config: %CrucibleIR.Training.Config{}`
- OR `training_config: map()`
- OR direct stage-specific keys (backward compatibility)

### 4.3 Config Mapping (Supervised)

| IR Field | Stage/Config Field | Notes |
|----------|--------------------|-------|
| `epochs` | `num_epochs` | direct map |
| `batch_size` | `batch_size` | direct map |
| `learning_rate` | `learning_rate` | direct map |
| `optimizer` | `training_config["optimizer"]` | kept in training_config map |
| `loss_function` | `training_config["loss_function"]` | kept in training_config map |
| `seed` | `training_config["seed"]` | for backend/session use |
| `gradient_clipping` | `training_config["gradient_clipping"]` | backend use |
| `checkpoint_every` | `save_every` | stage-level feature |
| `options` | merged into `training_config` | last-write wins |

Defaults remain those in `CrucibleTrain.Supervised.Config` unless explicitly set.

### 4.4 Dataset and Model Resolution

- `CrucibleIR.Training.Config.dataset_ref` should be resolved to a `CrucibleTrain.Supervised.Dataset` via `CrucibleTrain.Ports.DatasetStore` when `ports` are provided.
- `model_ref` should be passed into `training_config` map for `TrainingClient.start_session/2`.
- If ports are not available, stages must return `{:error, :missing_ports}`.

### 4.5 Options Conventions

`CrucibleIR.Training.Config.options` may include:
- `:lr_schedule` (mapped to `CrucibleTrain.Supervised.Config.lr_schedule`)
- `:log_path` (mapped to `log_path`)
- `:logger` (mapped to `logger`)
- `:save_every` (mapped to `save_every`)
- `:eval_every` (mapped to `eval_every`)
- `:adam_beta1`, `:adam_beta2`, `:adam_eps`

If present, these override defaults.

## 5) Error Handling

Normalization should fail fast with clear errors:

- `{:error, :missing_training_config}`
- `{:error, :missing_ports}`
- `{:error, :dataset_resolution_failed}`
- `{:error, :unsupported_training_config}`

## 6) Tests

Add tests to cover:

- Normalization from IR struct to `CrucibleTrain.Supervised.Config`.
- Backward compatibility with raw map options.
- Dataset resolution with a mock DatasetStore.
- Stage execution with IR config.

## 7) Acceptance Criteria

- `crucible_train` stages accept IR configs without breaking existing callers.
- IR dependency is actively used (no unused dep).
- Training loops remain IR-agnostic.
- Tests pass with no warnings or errors.

