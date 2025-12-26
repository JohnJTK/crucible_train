Mox.defmock(CrucibleTrain.Ports.TrainingClientMock, for: CrucibleTrain.Ports.TrainingClient)
Mox.defmock(CrucibleTrain.Ports.LLMClientMock, for: CrucibleTrain.Ports.LLMClient)
Mox.defmock(CrucibleTrain.Ports.BlobStoreMock, for: CrucibleTrain.Ports.BlobStore)
Mox.defmock(CrucibleTrain.Ports.DatasetStoreMock, for: CrucibleTrain.Ports.DatasetStore)
Mox.defmock(CrucibleTrain.Ports.HubClientMock, for: CrucibleTrain.Ports.HubClient)
Mox.defmock(CrucibleTrain.Ports.VectorStoreMock, for: CrucibleTrain.Ports.VectorStore)
Mox.defmock(CrucibleTrain.Ports.EmbeddingClientMock, for: CrucibleTrain.Ports.EmbeddingClient)

Mox.defmock(CrucibleTrain.Completers.TokenCompleterMock,
  for: CrucibleTrain.Completers.TokenCompleter
)

Mox.defmock(CrucibleTrain.Completers.MessageCompleterMock,
  for: CrucibleTrain.Completers.MessageCompleter
)

Mox.defmock(CrucibleTrain.Logging.LoggerMock, for: CrucibleTrain.Logging.Logger)
Mox.defmock(CrucibleTrain.Eval.EvaluatorMock, for: CrucibleTrain.Eval.Evaluator)

Mox.defmock(CrucibleTrain.Renderers.RendererMock, for: CrucibleTrain.Renderers.Renderer)

Mox.defmock(CrucibleTrain.Supervised.DatasetMock, for: CrucibleTrain.Supervised.Dataset)
Mox.defmock(CrucibleTrain.RL.EnvMock, for: CrucibleTrain.RL.Env)
Mox.defmock(CrucibleTrain.RL.EnvGroupBuilderMock, for: CrucibleTrain.RL.EnvGroupBuilder)
Mox.defmock(CrucibleTrain.RL.RLDatasetMock, for: CrucibleTrain.RL.RLDataset)
