# Prompt: Implement IR to Training Normalization

Date: 2025-12-26

## Goal

Implement the IR-to-training behavior specified in:
- `/home/home/p/g/North-Shore-AI/crucible_train/docs/20251226/ir_to_training_spec/IR_TO_TRAINING_SPEC.md`

## Required Reading (Full Paths)

### Repo Context
- `/home/home/p/g/North-Shore-AI/crucible_train/README.md`
- `/home/home/p/g/North-Shore-AI/crucible_train/CHANGELOG.md`
- `/home/home/p/g/North-Shore-AI/crucible_train/mix.exs`

### Training Config and Stages
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/supervised/config.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/supervised/train.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/stages/supervised_train.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/stages/rl_train.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/stages/dpo_train.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/stages/distillation.ex`

### Ports
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/ports/ports.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/ports/dataset_store.ex`
- `/home/home/p/g/North-Shore-AI/crucible_train/lib/crucible_train/ports/training_client.ex`

### IR Types
- `/home/home/p/g/North-Shore-AI/crucible_ir/lib/crucible_ir/training/config.ex`
- `/home/home/p/g/North-Shore-AI/crucible_ir/lib/crucible_ir/dataset_ref.ex`
- `/home/home/p/g/North-Shore-AI/crucible_ir/lib/crucible_ir/model_ref.ex`

### Design Doc
- `/home/home/p/g/North-Shore-AI/crucible_train/docs/20251226/ir_to_training_spec/IR_TO_TRAINING_SPEC.md`

## Context Summary

CrucibleTrain stages must accept `%CrucibleIR.Training.Config{}` and normalize it into stage-specific configs without pushing IR into training loops. The normalization layer lives in `crucible_train` and uses ports to resolve dataset/model refs.

## Implementation Requirements

1) Add a normalization module in `crucible_train` per spec.
2) Update all `CrucibleTrain` stage modules to accept IR config and call normalization.
3) Preserve backward compatibility with raw maps and existing stage options.
4) Add tests for normalization and stage usage with IR configs.

## TDD and Quality Gates

- Write tests first (ExUnit + Mox as needed).
- `mix test` must pass.
- `mix compile --warnings-as-errors` must be clean.
- `mix format` must be clean.
- `mix credo --strict` must be clean.
- `mix dialyzer` must be clean.

## Version Bump (Required)

- Bump version `0.x.y` in `/home/home/p/g/North-Shore-AI/crucible_train/mix.exs`.
- Update `/home/home/p/g/North-Shore-AI/crucible_train/README.md` to reflect the new version.
- Add a 2025-12-26 entry to `/home/home/p/g/North-Shore-AI/crucible_train/CHANGELOG.md`.

