defmodule SanitySync do
  @moduledoc """
  TODO
  """

  alias SanitySync.Doc
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

    * `types` - List of types to sync. If omitted, all types will be synced.

  All other options will be passed to `upsert_sanity_doc!/2`.
  """
  def sync_all(_opts \\ []) do
    # FIXME
    # FIXME types
  end

  @doc """
  Upserts a sanity document.

  ## Options

    * `transaction_callback` - Callback function to be called in same transaction as upsert.
  """
  def upsert_sanity_doc!(%{_id: id, _type: type} = doc, _opts \\ []) do
    Doc.changeset(%Doc{}, %{doc: doc, id: id, type: type})
    |> repo().insert!(conflict_target: :id, on_conflict: :replace_all)

    # FIXME transaction_callback
  end
end
