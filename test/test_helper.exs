{:ok, _pid} =
  Supervisor.start_link([SanitySync.Test.Repo],
    strategy: :one_for_one,
    name: SanitySync.Test.Supervisor
  )

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(SanitySync.Test.Repo, :manual)
