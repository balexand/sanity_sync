defmodule SanitySync do
  @moduledoc """
  TODO
  """

  alias SanitySync.Doc
  import UnsafeAtomizeKeys

  @upsert_opts_keys []

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

    * `types` - List of types to sync. If omitted, all types will be synced.

  All other options will be passed to `upsert_sanity_doc!/2`.
  """
  def sync_all(opts) do
    opts = Keyword.validate!(opts, [:sanity_config, :types] ++ @upsert_opts_keys)

    """
    *[_type in $types && !(_id in path("drafts.**"))]
    """
    |> Sanity.query(%{types: Keyword.fetch!(opts, :types)})
    |> Sanity.request!(Keyword.fetch!(opts, :sanity_config))
    |> Sanity.result!()
    |> Enum.map(&unsafe_atomize_keys/1)

    # FIXME paginate
    # FIXME types
  end

  @doc """
  Upserts a sanity document.

  ## Options

    * `transaction_callback` - Callback function to be called in same transaction as upsert.
  """
  def upsert_sanity_doc!(%{_id: id, _type: type} = doc, opts \\ []) do
    # FIXME _opts
    _opts = Keyword.validate!(opts, @upsert_opts_keys)

    Doc.changeset(%Doc{}, %{doc: doc, id: id, type: type})
    |> repo().insert!(conflict_target: :id, on_conflict: :replace_all)

    # FIXME transaction_callback
  end
end
