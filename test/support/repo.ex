defmodule Sanity.Sync.Test.Repo do
  use Ecto.Repo,
    otp_app: :sanity_sync,
    adapter: Ecto.Adapters.Postgres
end
