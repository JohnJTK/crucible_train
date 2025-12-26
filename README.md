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
    {:crucible_train, "~> 0.1.0"}
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

## Documentation

Full documentation available at [HexDocs](https://hexdocs.pm/crucible_train).

## License

MIT License - see [LICENSE](LICENSE) for details.
