import Config

if config_env() == :test do
  config :logger, level: :warn

  config :sanity_sync, ecto_repos: [Sanity.Sync.Test.Repo]

  config :sanity_sync, :repo, Sanity.Sync.Test.Repo

  config :sanity_sync, :sanity_client, Sanity.Sync.MockClient

  config :sanity_sync, Sanity.Sync.Test.Repo,
    database: "sanity_sync_test",
    username: "postgres",
    password: "postgres",
    hostname: "localhost",
    pool: Ecto.Adapters.SQL.Sandbox
end
