defmodule CrucibleTrain.Checkpoint do
  @moduledoc """
  Checkpoint utilities for saving and resuming training runs.
  """

  require Logger

  alias CrucibleTrain.Ports.TrainingClient

  @checkpoints_filename "checkpoints.jsonl"

  @type loop_state :: %{optional(:epoch) => integer(), optional(:batch) => integer()}
  @type checkpoint_result :: %{optional(String.t()) => String.t()}

  @spec load_checkpoints_file(String.t()) :: [map()]
  def load_checkpoints_file(log_dir) when is_binary(log_dir) do
    path = Path.join(log_dir, @checkpoints_filename)

    if File.exists?(path) do
      Logger.info("Reading checkpoints from #{path}")

      path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.map(&Jason.decode!/1)
    else
      Logger.info("No checkpoints found at #{path}")
      []
    end
  end

  @spec get_last_checkpoint(String.t(), String.t()) :: map() | nil
  def get_last_checkpoint(log_dir, required_key \\ "path") when is_binary(required_key) do
    checkpoints = load_checkpoints_file(log_dir)
    checkpoints_with_key = Enum.filter(checkpoints, &Map.has_key?(&1, required_key))

    case checkpoints_with_key do
      [] ->
        Logger.info("No checkpoints found with key #{required_key} in #{log_dir}")
        nil

      list ->
        last = List.last(list)

        Logger.info(
          "Found #{length(list)} valid checkpoints with key '#{required_key}' in #{log_dir}"
        )

        Logger.info("Using last checkpoint: #{inspect(last)}")
        last
    end
  end

  @spec save_checkpoint_async(term(), String.t(), String.t(), loop_state()) :: Task.t()
  def save_checkpoint_async(training_client, name, log_path, loop_state) do
    Task.async(fn ->
      save_checkpoint_internal(training_client, name, log_path, loop_state)
    end)
  end

  @spec save_checkpoint(term(), String.t(), String.t(), loop_state()) :: checkpoint_result()
  def save_checkpoint(training_client, name, log_path, loop_state) do
    save_checkpoint_async(training_client, name, log_path, loop_state)
    |> Task.await(:infinity)
  end

  defp save_checkpoint_internal(training_client, name, log_path, loop_state) do
    result =
      case training_client do
        {ports, session} ->
          TrainingClient.save_checkpoint(ports, session, name)

        %_{} = client ->
          module = client.__struct__

          if function_exported?(module, :save_checkpoint, 2) do
            module.save_checkpoint(client, name)
          else
            {:error, :save_checkpoint_not_supported}
          end
      end

    case result do
      :ok ->
        entry = Map.merge(%{"name" => name, "path" => name}, loop_state)
        write_checkpoint(log_path, entry)
        %{"path" => name}

      {:ok, %{"path" => _} = payload} ->
        entry = Map.merge(%{"name" => name}, loop_state) |> Map.merge(payload)
        write_checkpoint(log_path, entry)
        payload

      {:ok, %{path: _} = payload} ->
        entry = Map.merge(%{"name" => name}, loop_state) |> Map.merge(Map.new(payload))
        write_checkpoint(log_path, entry)
        Map.new(payload)

      {:error, reason} ->
        raise "Checkpoint save failed: #{inspect(reason)}"
    end
  end

  defp write_checkpoint(log_path, entry) do
    File.mkdir_p!(log_path)

    File.write!(Path.join(log_path, @checkpoints_filename), Jason.encode!(entry) <> "\n", [
      :append
    ])
  end
end
