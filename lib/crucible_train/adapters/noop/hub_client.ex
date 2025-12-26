defmodule CrucibleTrain.Adapters.Noop.HubClient do
  @moduledoc """
  No-op adapter for hub operations.
  """

  @behaviour CrucibleTrain.Ports.HubClient

  alias CrucibleTrain.Ports.Error

  defp error do
    Error.new(:hub_client, __MODULE__, "Hub adapter is not configured")
  end

  @impl true
  def download(_opts, _opts2), do: {:error, error()}

  @impl true
  def snapshot(_opts, _opts2), do: {:error, error()}

  @impl true
  def list_files(_opts, _repo_id, _opts2), do: {:error, error()}
end
