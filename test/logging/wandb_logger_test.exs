defmodule CrucibleTrain.Logging.WandbLoggerTest do
  use ExUnit.Case, async: true

  import Mox

  alias CrucibleTrain.Logging.WandbLogger

  setup :verify_on_exit!
  setup :set_mox_from_context

  defp base_opts do
    [
      api_key: "wandb-key",
      project: "demo-project",
      entity: "demo-entity",
      http_client: CrucibleTrain.HTTPClientMock,
      rate_limit: false
    ]
  end

  defp state_overrides(overrides) do
    struct!(
      WandbLogger,
      Map.merge(
        %{
          api_key: "wandb-key",
          project: "demo-project",
          entity: "demo-entity",
          run_id: "run-123",
          run_name: "run-name",
          display_name: "run-name",
          base_url: "https://api.wandb.ai",
          http_client: CrucibleTrain.HTTPClientMock,
          request_opts: [],
          history_step: 0,
          rate_limit: nil
        },
        overrides
      )
    )
  end

  defp graphql_response(bucket) do
    %{
      "data" => %{
        "upsertBucket" => %{
          "bucket" => bucket,
          "inserted" => true
        }
      }
    }
  end

  describe "init/1" do
    test "succeeds with valid configuration" do
      expect(CrucibleTrain.HTTPClientMock, :request, fn :post, url, body, headers, _opts ->
        assert url == "https://api.wandb.ai/graphql"
        assert body["query"] =~ "mutation UpsertBucket"
        assert body["variables"]["project"] == "demo-project"
        assert body["variables"]["entity"] == "demo-entity"
        assert body["variables"]["name"] == "run-name"

        # Verify Basic auth header
        auth_header = Enum.find(headers, fn {k, _} -> k == "Authorization" end)
        assert auth_header != nil
        {_, auth_value} = auth_header
        assert String.starts_with?(auth_value, "Basic ")

        {:ok,
         %{
           status: 200,
           body:
             graphql_response(%{
               "id" => "run-123",
               "name" => "abc123",
               "displayName" => "run-name",
               "project" => %{
                 "name" => "demo-project",
                 "entity" => %{"name" => "demo-entity"}
               }
             })
         }}
      end)

      opts = [run_name: "run-name", base_url: "https://api.wandb.ai"] ++ base_opts()

      assert {:ok, logger} = WandbLogger.init(opts)
      assert logger.run_id == "run-123"
      assert logger.run_name == "abc123"
      assert logger.entity == "demo-entity"
      assert logger.project == "demo-project"
    end

    test "fails without api_key" do
      # Temporarily unset the env var to test the validation
      original = System.get_env("WANDB_API_KEY")
      System.delete_env("WANDB_API_KEY")

      try do
        assert {:error, :missing_api_key} = WandbLogger.init(project: "demo-project")
      after
        if original, do: System.put_env("WANDB_API_KEY", original)
      end
    end

    test "fails without project" do
      assert {:error, :missing_project} = WandbLogger.init(api_key: "wandb-key")
    end

    test "returns error when API call fails" do
      expect(CrucibleTrain.HTTPClientMock, :request, fn :post, _url, _body, _headers, _opts ->
        {:ok, %{status: 500, body: "oops"}}
      end)

      assert {:error, {:http_error, 500, "oops"}} =
               WandbLogger.init(base_opts() ++ [base_url: "https://api.wandb.ai"])
    end

    test "returns error when GraphQL returns errors" do
      expect(CrucibleTrain.HTTPClientMock, :request, fn :post, _url, _body, _headers, _opts ->
        {:ok,
         %{
           status: 200,
           body: %{
             "errors" => [%{"message" => "Project not found"}]
           }
         }}
      end)

      assert {:error, {:graphql_error, "Project not found"}} =
               WandbLogger.init(base_opts() ++ [base_url: "https://api.wandb.ai"])
    end
  end

  describe "log_metrics/3" do
    test "posts metrics to file stream API" do
      state = state_overrides(%{})

      expect(CrucibleTrain.HTTPClientMock, :request, fn :post, url, body, _headers, _opts ->
        assert url == "https://api.wandb.ai/files/demo-entity/demo-project/run-name/file_stream"
        assert body["files"]["wandb-history.jsonl"]["offset"] == 0

        content = body["files"]["wandb-history.jsonl"]["content"]
        assert is_list(content)
        [history_json] = content
        history = Jason.decode!(history_json)
        assert history["_step"] == 12
        assert history["loss"] == 0.5
        assert history["details"]["inner"] == 1

        {:ok, %{status: 200, body: %{}}}
      end)

      assert :ok =
               WandbLogger.log_metrics(state, 12, %{loss: 0.5, details: %{inner: 1}})
    end

    test "handles API errors gracefully" do
      state = state_overrides(%{})

      expect(CrucibleTrain.HTTPClientMock, :request, fn :post, _url, _body, _headers, _opts ->
        {:ok, %{status: 503, body: "unavailable"}}
      end)

      assert :ok = WandbLogger.log_metrics(state, 1, %{loss: 1.0})
    end
  end

  describe "log_hparams/2" do
    test "posts config via GraphQL" do
      state = state_overrides(%{})

      expect(CrucibleTrain.HTTPClientMock, :request, fn :post, url, body, _headers, _opts ->
        assert url == "https://api.wandb.ai/graphql"
        assert body["query"] =~ "mutation UpsertBucket"
        assert body["variables"]["id"] == "run-123"

        config = Jason.decode!(body["variables"]["config"])
        assert config["optimizer"]["name"] == "adam"
        assert config["optimizer"]["beta"] == 0.9

        {:ok, %{status: 200, body: graphql_response(%{"id" => "run-123"})}}
      end)

      assert :ok =
               WandbLogger.log_hparams(state, %{optimizer: %{name: "adam", beta: 0.9}})
    end
  end

  describe "close/1" do
    test "sends complete signal via file stream" do
      state = state_overrides(%{})

      expect(CrucibleTrain.HTTPClientMock, :request, fn :post, url, body, _headers, _opts ->
        assert url == "https://api.wandb.ai/files/demo-entity/demo-project/run-name/file_stream"
        assert body["complete"] == true
        assert body["exitcode"] == 0
        {:ok, %{status: 200, body: %{}}}
      end)

      assert :ok = WandbLogger.close(state)
    end
  end

  describe "get_url/1" do
    test "returns formatted URL using run_name" do
      state = state_overrides(%{})

      assert WandbLogger.get_url(state) ==
               "https://wandb.ai/demo-entity/demo-project/runs/run-name"
    end
  end

  describe "log_long_text/3" do
    test "sends summary via GraphQL" do
      state = state_overrides(%{})

      expect(CrucibleTrain.HTTPClientMock, :request, fn :post, url, body, _headers, _opts ->
        assert url == "https://api.wandb.ai/graphql"
        assert body["query"] =~ "mutation UpsertBucket"

        summary = Jason.decode!(body["variables"]["summaryMetrics"])
        assert summary["notes"] == "Some long text here"

        {:ok, %{status: 200, body: graphql_response(%{"id" => "run-123"})}}
      end)

      assert :ok = WandbLogger.log_long_text(state, "notes", "Some long text here")
    end
  end
end
