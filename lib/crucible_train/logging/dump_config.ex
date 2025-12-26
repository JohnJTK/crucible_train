defmodule CrucibleTrain.Logging.DumpConfig do
  @moduledoc """
  Helpers for serializing config structs into JSON-friendly maps.
  """

  @spec dump(term()) :: term()
  def dump(config) when is_struct(config) do
    config
    |> Map.from_struct()
    |> dump()
  end

  def dump(config) when is_map(config) do
    config
    |> Enum.map(fn {k, v} -> {to_string(k), dump(v)} end)
    |> Map.new()
  end

  def dump(config) when is_list(config) do
    Enum.map(config, &dump/1)
  end

  def dump(config) when is_tuple(config) do
    config
    |> Tuple.to_list()
    |> dump()
  end

  def dump(config) when is_atom(config), do: to_string(config)
  def dump(config), do: config
end
