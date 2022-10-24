Mox.defmock(Sanity.Sync.MockClient, for: Sanity.Behaviour)

defmodule Sanity.Sync.CallbackBehaviour do
  @callback callback(map()) :: any()
end

Mox.defmock(Sanity.Sync.MockCallback, for: Sanity.Sync.CallbackBehaviour)
