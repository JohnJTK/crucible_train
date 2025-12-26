defmodule CrucibleTrain.Distillation.DatasetsTest do
  use ExUnit.Case, async: true

  alias CrucibleTrain.Distillation.{PromptOnlyDataset, PromptOnlyEnv}
  alias CrucibleTrain.Renderers.RoleColon
  alias CrucibleTrain.Test.MockTokenizer

  test "prompt dataset yields problem group builders" do
    {:ok, state} = RoleColon.init(tokenizer: MockTokenizer)

    dataset =
      PromptOnlyDataset.new(["Hi", "Hello"],
        batch_size: 1,
        group_size: 2,
        renderer_module: RoleColon,
        renderer_state: state,
        tokenizer: MockTokenizer
      )

    [builder] = PromptOnlyDataset.get_batch(dataset, 0)
    env = builder.env_thunk.()
    assert %PromptOnlyEnv{} = env
    assert PromptOnlyDataset.length(dataset) == 2
  end
end
