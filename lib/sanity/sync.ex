defmodule Sanity.Sync do
  @moduledoc """
  TODO
  """

  import Ecto.Query
  alias Sanity.Sync.Doc
  import UnsafeAtomizeKeys

  defp repo, do: Application.fetch_env!(:sanity_sync, :repo)

  @doc """
  Gets a single document. Returns `nil` if document does not exist.
  """
  def get_doc(id) do
    case repo().get(Doc, id) do
      nil -> nil
      %Doc{doc: doc} -> unsafe_atomize_keys(doc)
    end
  end

  @doc """
  Gets a single document. Raises `Ecto.NoResultsError` if document does not exist.
  """
  def get_doc!(id) do
    repo().get!(Doc, id).doc |> unsafe_atomize_keys()
  end

  @doc """
  Fetches a single document from Sanity. If the document exists then `upsert_sanity_doc!/2` will
  be called. If the document doesn't exist, then the `Sanity.Sync.Doc` for that document will be
  deleted.

  This function can be called when a webhook is received to sync a document.

  ## Options

    * `callback` - Callback function that will be called after the document is upserted. It will
      be passed a map like `%{doc: doc, repo: repo}`. This callback is not called when the record
      is deleted.
    * `sanity_config` - Sanity configuration. See `Sanity.request/2`.
  """
  def sync(id, opts) when is_binary(id) do
    opts = Keyword.validate!(opts, [:callback, :sanity_config])

    """
    *[_id == $id]
    """
    |> Sanity.query(%{id: id})
    |> request!(Keyword.fetch!(opts, :sanity_config))
    |> Sanity.result!()
    |> case do
      [doc] -> doc |> unsafe_atomize_keys() |> upsert_sanity_doc!(opts)
      [] -> repo().delete_all(from d in Doc, where: d.id == ^id)
    end
  end

  @doc """
  Fetches all documents from Sanity and calls `upsert_sanity_doc!/2`.

  ## Options

    * `callback` - Callback function that will be called after each document is upserted. It will
      be passed a map like `%{doc: doc, repo: repo}`.
    * `sanity_config` - Sanity configuration. See `Sanity.request/2`.
    * `types` - List of types to sync. If omitted, all types will be synced.
  """
  def sync_all(opts) do
    opts = Keyword.validate!(opts, [:callback, :sanity_config, :types])

    """
    *[_type in $types && !(_id in path("drafts.**"))]
    """
    |> Sanity.query(%{types: Keyword.fetch!(opts, :types)})
    |> request!(Keyword.fetch!(opts, :sanity_config))
    |> Sanity.result!()
    |> Enum.map(&unsafe_atomize_keys/1)
    |> Enum.each(&upsert_sanity_doc!(&1, opts))

    # FIXME paginate
  end

  @doc """
  Upserts a sanity document.
  """
  def upsert_sanity_doc!(%{_id: id, _type: type} = doc, opts \\ []) do
    Doc.changeset(%Doc{}, %{doc: doc, id: id, type: type})
    |> repo().insert!(conflict_target: :id, on_conflict: :replace_all)
    |> tap(fn _ ->
      case Keyword.fetch(opts, :callback) do
        {:ok, cb} -> cb.(%{doc: doc, repo: repo()})
        :error -> nil
      end
    end)
  end

  defp request!(request, config) do
    Application.get_env(:sanity_sync, :sanity_client, Sanity).request!(request, config)
  end
end
