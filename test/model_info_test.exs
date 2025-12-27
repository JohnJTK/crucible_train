defmodule CrucibleTrain.ModelInfoTest do
  use ExUnit.Case, async: true

  defmodule MinimalModelInfo do
    @behaviour CrucibleTrain.ModelInfo

    @impl true
    def get_config(_), do: {:ok, %{model_name: "test"}}
  end

  defmodule FullModelInfo do
    @behaviour CrucibleTrain.ModelInfo

    @impl true
    def get_config(_), do: {:ok, %{model_name: "test"}}

    @impl true
    def count_parameters(_), do: {:ok, 123}

    @impl true
    def get_special_tokens(_), do: {:ok, %{bos: "<s>"}}
  end

  test "minimal implementation provides required callback" do
    assert function_exported?(MinimalModelInfo, :get_config, 1)
  end

  test "full implementation supports optional callbacks" do
    assert function_exported?(FullModelInfo, :count_parameters, 1)
    assert function_exported?(FullModelInfo, :get_special_tokens, 1)
  end
end
