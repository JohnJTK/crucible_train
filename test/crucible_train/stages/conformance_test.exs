defmodule CrucibleTrain.Stages.ConformanceTest do
  @moduledoc """
  Conformance tests for training stage describe/1 contracts.

  Verifies all training stages implement the canonical schema format:
  - name: atom
  - description: string
  - required: list of atoms
  - optional: list of atoms
  - types: map with valid type specifications
  """
  use ExUnit.Case

  alias CrucibleTrain.Stages.{
    Distillation,
    DPOTrain,
    RLTrain,
    SupervisedTrain
  }

  @moduletag :conformance

  @stages [
    SupervisedTrain,
    DPOTrain,
    RLTrain,
    Distillation
  ]

  @primitive_types [:string, :integer, :float, :boolean, :atom, :map, :list, :module, :any]

  describe "all training stages implement describe/1" do
    for stage <- @stages do
      test "#{inspect(stage)} has describe/1" do
        assert function_exported?(unquote(stage), :describe, 1),
               "Stage #{inspect(unquote(stage))} must implement describe/1"
      end

      test "#{inspect(stage)} returns valid schema" do
        schema = unquote(stage).describe(%{})
        assert is_atom(schema.name), "name must be an atom"
        assert is_binary(schema.description), "description must be a string"
        assert is_list(schema.required), "required must be a list"
        assert is_list(schema.optional), "optional must be a list"
        assert is_map(schema.types), "types must be a map"
      end

      test "#{inspect(stage)} has types for all required fields" do
        schema = unquote(stage).describe(%{})

        for key <- schema.required do
          assert Map.has_key?(schema.types, key),
                 "Required field #{key} missing from types"
        end
      end

      test "#{inspect(stage)} has types for all optional fields" do
        schema = unquote(stage).describe(%{})

        for key <- schema.optional do
          assert Map.has_key?(schema.types, key),
                 "Optional field #{key} missing from types"
        end
      end

      test "#{inspect(stage)} has no overlap between required and optional" do
        schema = unquote(stage).describe(%{})

        overlap =
          MapSet.intersection(
            MapSet.new(schema.required),
            MapSet.new(schema.optional)
          )

        assert MapSet.size(overlap) == 0,
               "Fields #{inspect(MapSet.to_list(overlap))} appear in both required and optional"
      end

      test "#{inspect(stage)} has valid type specifications" do
        schema = unquote(stage).describe(%{})

        for {key, type_spec} <- schema.types do
          assert valid_type_spec?(type_spec),
                 "Invalid type spec for :#{key}: #{inspect(type_spec)}"
        end
      end
    end
  end

  describe "stage-specific schemas" do
    test "supervised_train has expected schema" do
      schema = SupervisedTrain.describe(%{})
      assert schema.name == :supervised_train
      assert :epochs in schema.optional
      assert :batch_size in schema.optional
      assert :learning_rate in schema.optional
      assert :optimizer in schema.optional
      assert :loss_fn in schema.optional
      assert :metrics in schema.optional
      assert schema.types.epochs == :integer
      assert schema.types.batch_size == :integer
      assert schema.types.learning_rate == :float
      assert schema.types.optimizer == :atom
      assert schema.types.loss_fn == :atom
      assert schema.types.metrics == {:list, :atom}
    end

    test "dpo_train has expected schema" do
      schema = DPOTrain.describe(%{})
      assert schema.name == :dpo_train
      assert :beta in schema.optional
      assert :epochs in schema.optional
      assert :batch_size in schema.optional
      assert :learning_rate in schema.optional
      assert :reference_model in schema.optional
      assert schema.types.beta == :float
      assert schema.types.epochs == :integer
      assert schema.types.batch_size == :integer
      assert schema.types.learning_rate == :float
      assert schema.types.reference_model == :string
    end

    test "rl_train has expected schema" do
      schema = RLTrain.describe(%{})
      assert schema.name == :rl_train
      assert :algorithm in schema.optional
      assert :gamma in schema.optional
      assert :epsilon in schema.optional
      assert :learning_rate in schema.optional
      assert :episodes in schema.optional
      assert :reward_fn in schema.optional
      assert {:enum, [:ppo, :dqn, :a2c, :reinforce]} = schema.types.algorithm
      assert schema.types.gamma == :float
      assert schema.types.epsilon == :float
      assert schema.types.learning_rate == :float
      assert schema.types.episodes == :integer
      assert schema.types.reward_fn == {:function, 1}
    end

    test "distillation has expected schema" do
      schema = Distillation.describe(%{})
      assert schema.name == :distillation
      assert :teacher_model in schema.optional
      assert :student_model in schema.optional
      assert :temperature in schema.optional
      assert :alpha in schema.optional
      assert :epochs in schema.optional
      assert schema.types.teacher_model == :string
      assert schema.types.student_model == :string
      assert schema.types.temperature == :float
      assert schema.types.alpha == :float
      assert schema.types.epochs == :integer
    end
  end

  describe "run/2 callback exists" do
    for stage <- @stages do
      test "#{inspect(stage)} has run/2" do
        assert function_exported?(unquote(stage), :run, 2),
               "Stage #{inspect(unquote(stage))} must implement run/2"
      end
    end
  end

  # Type spec validation helpers

  defp valid_type_spec?(spec) when spec in @primitive_types, do: true
  defp valid_type_spec?({:struct, mod}) when is_atom(mod), do: true
  defp valid_type_spec?({:enum, values}) when is_list(values), do: true
  defp valid_type_spec?({:list, inner}), do: valid_type_spec?(inner)
  defp valid_type_spec?({:map, k, v}), do: valid_type_spec?(k) and valid_type_spec?(v)
  defp valid_type_spec?({:function, arity}) when is_integer(arity) and arity >= 0, do: true

  defp valid_type_spec?({:union, types}) when is_list(types),
    do: Enum.all?(types, &valid_type_spec?/1)

  defp valid_type_spec?({:tuple, types}) when is_list(types),
    do: Enum.all?(types, &valid_type_spec?/1)

  defp valid_type_spec?(_), do: false
end
