ExUnit.start()
Application.ensure_all_started(:mox)

Code.require_file("support/mocks.ex", __DIR__)
Code.require_file("support/mock_tokenizer.ex", __DIR__)
Code.require_file("support/mock_tokenizer_special.ex", __DIR__)
