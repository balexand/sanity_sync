defmodule Sanity.Sync.MockBehaviour do
  @callback request!(Sanity.Request.t(), keyword()) :: Sanity.Response.t()
end

Mox.defmock(Sanity.Sync.MockClient, for: Sanity.Sync.MockBehaviour)

defmodule Sanity.Sync.CallbackBehaviour do
  @callback callback(map()) :: any()
end

Mox.defmock(Sanity.Sync.MockCallback, for: Sanity.Sync.CallbackBehaviour)
