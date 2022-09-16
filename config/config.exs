import Config

if config_env() == :test do
  config :logger, level: :warn

  config :sanity_sync, ecto_repos: [SanitySync.Test.Repo]

  config :sanity_sync, :repo, SanitySync.Test.Repo

  config :sanity_sync, SanitySync.Test.Repo,
    database: "sanity_sync_test",
    username: "postgres",
    password: "postgres",
    hostname: "localhost",
    pool: Ecto.Adapters.SQL.Sandbox
end
