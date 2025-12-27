defmodule CrucibleTrain.Eval.ScoringTest do
  use ExUnit.Case, async: true

  alias CrucibleTrain.Eval.Scoring

  test "exact_match scores trimmed strings" do
    assert Scoring.score(:exact_match, "Hi", "Hi") == 1.0
    assert Scoring.score(:exact_match, " Hi ", "Hi") == 1.0
    assert Scoring.score(:exact_match, "Hi", "Bye") == 0.0
  end

  test "contains scores substring matches" do
    assert Scoring.score(:contains, "hello world", "world") == 1.0
    assert Scoring.score(:contains, "hello", "world") == 0.0
  end

  test "raises on unknown scorer" do
    assert_raise ArgumentError, ~r/Unknown scoring method/, fn ->
      Scoring.score(:unknown, "a", "b")
    end
  end
end
