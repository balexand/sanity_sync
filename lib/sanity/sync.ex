defmodule Sanity.Sync do
  @moduledoc """
  TODO
  """

  alias Sanity.Sync.Doc
  import UnsafeAtomizeKeys

  defp repo, do: Application.fetch_env!(:sanity_sync, :repo)

  @doc """
  Gets a single document. Raises `Ecto.NoResultsError` if document does not exist.
  """
  def get_doc!(id) do
    repo().get!(Doc, id).doc |> unsafe_atomize_keys()
  end

  @doc """
  Fetches all documents from Sanity and calls `upsert_sanity_doc!/2`.

  ## Options

    * `callback` - TODO doc
    * `sanity_config` - Sanity configuration. See `Sanity.request/2`.
    * `types` - List of types to sync. If omitted, all types will be synced.

  All other options will be passed to `upsert_sanity_doc!/2`.
  """
  def sync_all(opts) do
    opts = Keyword.validate!(opts, [:callback, :sanity_config, :types])

    """
    *[_type in $types && !(_id in path("drafts.**"))]
    """
    |> Sanity.query(%{types: Keyword.fetch!(opts, :types)})
    |> Sanity.request!(Keyword.fetch!(opts, :sanity_config))
    |> Sanity.result!()
    |> Enum.map(&unsafe_atomize_keys/1)
    |> Enum.each(fn doc ->
      upsert_sanity_doc!(doc)

      case Keyword.fetch(opts, :callback) do
        {:ok, cb} -> cb.(%{doc: doc, repo: repo()})
        :error -> nil
      end
    end)

    # FIXME paginate
  end

  @doc """
  Upserts a sanity document.
  """
  def upsert_sanity_doc!(%{_id: id, _type: type} = doc) do
    Doc.changeset(%Doc{}, %{doc: doc, id: id, type: type})
    |> repo().insert!(conflict_target: :id, on_conflict: :replace_all)
  end
end
