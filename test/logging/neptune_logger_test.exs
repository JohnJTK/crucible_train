defmodule CrucibleTrain.Logging.NeptuneLoggerTest do
  use ExUnit.Case, async: true

  import Mox

  alias CrucibleTrain.Logging.NeptuneLogger

  setup :verify_on_exit!
  setup :set_mox_from_context

  @base_url "https://app.neptune.ai"

  defp base_opts do
    [
      api_token: "neptune-token",
      project: "workspace/project",
      base_url: @base_url,
      http_client: CrucibleTrain.HTTPClientMock,
      rate_limit: false
    ]
  end

  defp state_overrides(overrides) do
    struct!(
      NeptuneLogger,
      Map.merge(
        %{
          api_token: "neptune-token",
          access_token: "access-token-123",
          project: "workspace/project",
          project_id: "proj-uuid",
          run_id: "run-uuid",
          sys_id: "RUN-1",
          workspace: "workspace",
          base_url: @base_url,
          http_client: CrucibleTrain.HTTPClientMock,
          request_opts: [],
          rate_limit: nil
        },
        overrides
      )
    )
  end

  defp expect_token_exchange do
    expect(CrucibleTrain.HTTPClientMock, :request, fn :post, url, _body, headers, _opts ->
      assert url == "#{@base_url}/api/backend/v1/authorization/api-token/exchange"

      # Verify X-Neptune-Api-Token header
      token_header = Enum.find(headers, fn {k, _} -> k == "X-Neptune-Api-Token" end)
      assert token_header != nil
      {_, token_value} = token_header
      assert token_value == "neptune-token"

      {:ok,
       %{
         status: 200,
         body: %{
           "accessToken" => "access-token-123",
           "refreshToken" => "refresh-token-456"
         }
       }}
    end)
  end

  defp expect_get_project do
    expect(CrucibleTrain.HTTPClientMock, :request, fn :get, url, _body, headers, _opts ->
      assert url == "#{@base_url}/api/backend/v1/projects/workspace%2Fproject"

      # Verify Bearer token
      auth_header = Enum.find(headers, fn {k, _} -> k == "Authorization" end)
      assert auth_header != nil
      {_, auth_value} = auth_header
      assert auth_value == "Bearer access-token-123"

      {:ok,
       %{
         status: 200,
         body: %{
           "id" => "proj-uuid",
           "name" => "project",
           "organizationName" => "workspace"
         }
       }}
    end)
  end

  defp expect_create_run do
    expect(CrucibleTrain.HTTPClientMock, :request, fn :post, url, body, headers, _opts ->
      assert url == "#{@base_url}/api/leaderboard/v1/experiments"

      # Verify Bearer token
      auth_header = Enum.find(headers, fn {k, _} -> k == "Authorization" end)
      assert auth_header != nil
      {_, auth_value} = auth_header
      assert auth_value == "Bearer access-token-123"

      # Verify body
      assert body["projectIdentifier"] == "proj-uuid"
      assert body["parentId"] == "proj-uuid"
      assert body["type"] == "run"

      {:ok,
       %{
         status: 200,
         body: %{
           "id" => "run-uuid",
           "shortId" => "RUN-1",
           "organizationName" => "workspace",
           "projectName" => "project"
         }
       }}
    end)
  end

  describe "init/1" do
    test "succeeds with valid configuration" do
      expect_token_exchange()
      expect_get_project()
      expect_create_run()

      assert {:ok, logger} = NeptuneLogger.init(base_opts())
      assert logger.run_id == "run-uuid"
      assert logger.sys_id == "RUN-1"
      assert logger.access_token == "access-token-123"
      assert logger.project_id == "proj-uuid"
    end

    test "fails without api_token" do
      # Temporarily unset the env var to test the validation
      original = System.get_env("NEPTUNE_API_TOKEN")
      System.delete_env("NEPTUNE_API_TOKEN")

      try do
        assert {:error, :missing_api_token} = NeptuneLogger.init(project: "workspace/project")
      after
        if original, do: System.put_env("NEPTUNE_API_TOKEN", original)
      end
    end

    test "fails without project" do
      assert {:error, :missing_project} = NeptuneLogger.init(api_token: "neptune-token")
    end

    test "returns error when token exchange fails" do
      expect(CrucibleTrain.HTTPClientMock, :request, fn :post, _url, _body, _headers, _opts ->
        {:ok, %{status: 401, body: "unauthorized"}}
      end)

      assert {:error, {:http_error, 401, "unauthorized"}} = NeptuneLogger.init(base_opts())
    end

    test "returns error when project lookup fails" do
      expect_token_exchange()

      expect(CrucibleTrain.HTTPClientMock, :request, fn :get, _url, _body, _headers, _opts ->
        {:ok, %{status: 404, body: "Project not found"}}
      end)

      assert {:error, {:http_error, 404, "Project not found"}} = NeptuneLogger.init(base_opts())
    end
  end

  describe "log_metrics/3" do
    test "posts metrics via executeOperations API" do
      state = state_overrides(%{})

      expect(CrucibleTrain.HTTPClientMock, :request, fn :post, url, body, headers, _opts ->
        assert url == "#{@base_url}/api/leaderboard/v1/experiments/run-uuid/operations"

        # Verify Bearer token
        auth_header = Enum.find(headers, fn {k, _} -> k == "Authorization" end)
        {_, auth_value} = auth_header
        assert auth_value == "Bearer access-token-123"

        # Verify operations
        assert is_list(body["operations"])
        [op] = body["operations"]
        assert op["path"] == "metrics/accuracy"
        assert op["logFloats"]["entries"] != nil
        [entry] = op["logFloats"]["entries"]
        assert entry["value"] == 0.9
        assert entry["step"] == 5.0

        {:ok, %{status: 200, body: []}}
      end)

      assert :ok = NeptuneLogger.log_metrics(state, 5, %{accuracy: 0.9})
    end

    test "handles nested metrics" do
      state = state_overrides(%{})

      expect(CrucibleTrain.HTTPClientMock, :request, fn :post, _url, body, _headers, _opts ->
        ops = body["operations"]
        paths = Enum.map(ops, & &1["path"])
        assert "metrics/train/loss" in paths
        assert "metrics/train/acc" in paths

        {:ok, %{status: 200, body: []}}
      end)

      assert :ok = NeptuneLogger.log_metrics(state, 1, %{train: %{loss: 0.5, acc: 0.8}})
    end

    test "handles API errors gracefully" do
      state = state_overrides(%{})

      expect(CrucibleTrain.HTTPClientMock, :request, fn :post, _url, _body, _headers, _opts ->
        {:ok, %{status: 503, body: "unavailable"}}
      end)

      assert :ok = NeptuneLogger.log_metrics(state, 1, %{loss: 1.0})
    end
  end

  describe "log_hparams/2" do
    test "posts config via executeOperations with assign operations" do
      state = state_overrides(%{})

      expect(CrucibleTrain.HTTPClientMock, :request, fn :post, url, body, _headers, _opts ->
        assert url == "#{@base_url}/api/leaderboard/v1/experiments/run-uuid/operations"

        ops = body["operations"]
        assert length(ops) == 2

        # Find the operations by path
        name_op = Enum.find(ops, &(&1["path"] == "parameters/optimizer/name"))
        beta_op = Enum.find(ops, &(&1["path"] == "parameters/optimizer/beta"))

        assert name_op["assignString"]["value"] == "adam"
        assert beta_op["assignFloat"]["value"] == 0.9

        {:ok, %{status: 200, body: []}}
      end)

      assert :ok = NeptuneLogger.log_hparams(state, %{optimizer: %{name: "adam", beta: 0.9}})
    end
  end

  describe "close/1" do
    test "sets run state to Idle" do
      state = state_overrides(%{})

      expect(CrucibleTrain.HTTPClientMock, :request, fn :post, url, body, _headers, _opts ->
        assert url == "#{@base_url}/api/leaderboard/v1/experiments/run-uuid/operations"

        [op] = body["operations"]
        assert op["path"] == "sys/state"
        assert op["assignString"]["value"] == "Idle"

        {:ok, %{status: 200, body: []}}
      end)

      assert :ok = NeptuneLogger.close(state)
    end
  end

  describe "get_url/1" do
    test "returns formatted URL with sys_id" do
      state = state_overrides(%{})

      assert NeptuneLogger.get_url(state) ==
               "https://app.neptune.ai/workspace/project/e/RUN-1"
    end
  end

  describe "log_long_text/3" do
    test "logs text via assignString operation" do
      state = state_overrides(%{})

      expect(CrucibleTrain.HTTPClientMock, :request, fn :post, url, body, _headers, _opts ->
        assert url == "#{@base_url}/api/leaderboard/v1/experiments/run-uuid/operations"

        [op] = body["operations"]
        assert op["path"] == "notes"
        assert op["assignString"]["value"] == "Some long text here"

        {:ok, %{status: 200, body: []}}
      end)

      assert :ok = NeptuneLogger.log_long_text(state, "notes", "Some long text here")
    end
  end
end
