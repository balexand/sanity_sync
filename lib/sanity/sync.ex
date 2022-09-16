defmodule Sanity.Sync do
  @moduledoc """
  TODO
  """

  alias Sanity.Sync.Doc
  import UnsafeAtomizeKeys

  @upsert_opts_keys [:transaction_callback]

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

    * `sanity_config` - Sanity configuration. See `Sanity.request/2`.
    * `types` - List of types to sync. If omitted, all types will be synced.

  All other options will be passed to `upsert_sanity_doc!/2`.
  """
  def sync_all(opts) do
    {upsert_opts, opts} = Keyword.split(opts, @upsert_opts_keys)
    opts = Keyword.validate!(opts, [:sanity_config, :types])

    """
    *[_type in $types && !(_id in path("drafts.**"))]
    """
    |> Sanity.query(%{types: Keyword.fetch!(opts, :types)})
    |> Sanity.request!(Keyword.fetch!(opts, :sanity_config))
    |> Sanity.result!()
    |> Enum.map(&unsafe_atomize_keys/1)
    |> Enum.each(&upsert_sanity_doc!(&1, upsert_opts))

    # FIXME paginate
  end

  @doc """
  Upserts a sanity document.

  ## Options

    * `transaction_callback` - Callback function to be called in same transaction as upsert.
  """
  def upsert_sanity_doc!(%{_id: id, _type: type} = doc, opts \\ []) do
    opts = Keyword.validate!(opts, @upsert_opts_keys)

    Doc.changeset(%Doc{}, %{doc: doc, id: id, type: type})
    |> Ecto.Changeset.prepare_changes(fn changeset ->
      case Keyword.fetch(opts, :transaction_callback) do
        {:ok, cb} -> cb.(%{doc: doc, repo: changeset.repo})
        :error -> nil
      end

      changeset
    end)
    |> repo().insert!(conflict_target: :id, on_conflict: :replace_all)
  end
end
