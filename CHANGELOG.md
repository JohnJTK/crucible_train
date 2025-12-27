# Changelog

## 0.2.0 (2025-12-26)

### Added

- W&B (Weights & Biases) logger backend via HTTP API
- Neptune.ai logger backend via HTTP API
- **Rate limiting for cloud loggers** with configurable settings:
  - Token bucket algorithm with minimum interval enforcement
  - Automatic retry with exponential backoff on 429 errors
  - Enabled by default (W&B: 500ms interval, Neptune: 200ms interval)
  - Configurable via `rate_limit: [min_interval_ms: n, max_retries: n]`
  - Can be disabled with `rate_limit: false`
- Scoring behaviour with pluggable scorers (ExactMatch, Contains, SemanticSimilarity)
- SemanticSimilarity scorer using embeddings
- Batch evaluation runner with streaming support
- LR warmup support in learning rate scheduling
- ModelInfo behaviour for model introspection
- Comprehensive examples for all integrations (`examples/` directory)
  - JSON logger, PrettyPrint logger, Multiplex logger
  - W&B and Neptune.ai cloud logging
  - Scoring functions and batch evaluation
  - Learning rate scheduling with warmup

### Changed

- Added `req` HTTP client dependency (~> 0.5)
- Updated logging module with wandb/neptune resolution
- Updated `crucible_ir` to ~> 0.2.1

## 0.1.1 (2025-12-25)

### Changed

- Added `ecto_sql` dependency (~> 3.11)
- Updated `crucible_framework` from ~> 0.3.0 (optional) to ~> 0.4.0 (required)
- Updated `crucible_ir` from ~> 0.1.1 (optional) to ~> 0.2.0 (required)

## 0.1.0

- Initial release.
