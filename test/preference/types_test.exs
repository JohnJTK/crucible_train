defmodule CrucibleTrain.Preference.TypesTest do
  use ExUnit.Case, async: true

  alias CrucibleTrain.Preference.{Comparison, LabeledComparison}
  alias CrucibleTrain.Renderers.Types

  test "comparison swap swaps completions" do
    comparison = %Comparison{
      prompt_conversation: [Types.message("user", "Q")],
      completion_a: [Types.message("assistant", "A")],
      completion_b: [Types.message("assistant", "B")]
    }

    swapped = Comparison.swap(comparison)
    assert swapped.completion_a == comparison.completion_b
    assert swapped.completion_b == comparison.completion_a
  end

  test "labeled comparison swap flips label" do
    comparison = %Comparison{
      prompt_conversation: [],
      completion_a: [],
      completion_b: []
    }

    labeled = %LabeledComparison{comparison: comparison, label: "A"}
    swapped = LabeledComparison.swap(labeled)

    assert swapped.label == "B"
    assert swapped.comparison.completion_a == labeled.comparison.completion_b
  end
end
