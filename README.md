# `Sanity.Sync`

[![Package](https://img.shields.io/hexpm/v/sanity_sync.svg)](https://hex.pm/packages/sanity_sync) [![Documentation](http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat)](https://hexdocs.pm/sanity_sync) ![CI](https://github.com/balexand/sanity_sync/actions/workflows/elixir.yml/badge.svg)

For syncing content from Sanity CMS to Ecto/PostgreSQL.

## Installation

The package can be installed by adding `sanity_sync` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sanity_sync, "~> 0.1"}
  ]
end
```

See the [docs](https://hexdocs.pm/sanity_sync/Sanity.Sync.html) for usage.

## Configuration

Configure Ecto repo:

```elixir
config :sanity_sync, :repo, MyApp.Repo
```

## Migrations

Copy the [migrations](https://github.com/balexand/sanity_sync/tree/main/priv/repo/migrations) from this project to your app.
