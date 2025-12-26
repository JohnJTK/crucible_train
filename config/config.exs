import Config

config :crucible_train,
  default_renderer: CrucibleTrain.Renderers.Llama3,
  default_logger: CrucibleTrain.Logging.JsonLogger,
  parity_mode: System.get_env("PARITY_MODE") == "1",
  trace_enabled: false

import_config "#{config_env()}.exs"
