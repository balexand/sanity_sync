defmodule Sanity.Sync.Doc do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  @timestamps_opts [type: :utc_datetime]
  schema "sanity_sync_docs" do
    field :doc, :map
    field :type, :string

    timestamps()
  end

  @doc false
  def changeset(feed_item, attrs) do
    required = [:id, :doc, :type]

    feed_item
    |> cast(attrs, required)
    |> validate_required(required)
  end
end
