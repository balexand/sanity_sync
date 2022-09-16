{:ok, _pid} =
  Supervisor.start_link([Sanity.Sync.Test.Repo],
    strategy: :one_for_one,
    name: Sanity.Sync.Test.Supervisor
  )

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Sanity.Sync.Test.Repo, :manual)
