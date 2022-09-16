defmodule SanitySync.Test.Repo.Migrations.CreateDocs do
  use Ecto.Migration

  def change do
    create table(:sanity_sync_docs, primary_key: false) do
      add :id, :string, primary_key: true
      add :type, :string, null: false
      add :doc, :map, null: false

      timestamps()
    end
  end
end
