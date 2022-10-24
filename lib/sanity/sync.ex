defmodule Sanity.Sync do
  @moduledoc """
  For syncing content from Sanity CMS to Ecto.

  ## Suggested strategy for syncing

  * Call `sync/2` when a webhook is called to immediately create, update, or delete the document.
  * Use `sync_all/1` for the inital import of documents and to reconcile created/updates webhooks
    that were missed.
  * TODO `reconcile_deleted` to reconcile any deleted webhooks that were missed.
  """

  import Ecto.Query
  alias Sanity.Sync.Doc
  import UnsafeAtomizeKeys

  @callback_opt_schema {
    :callback,
    # nimble_options doens't support function type
    type: :any,
    doc:
      "Callback function that will be called after the document is upserted. It will be passed a map like `%{doc: doc, repo: repo}`. This callback is not called when the record is deleted."
  }

  @request_opts_opt_schema {
    :request_opts,
    type: :keyword_list, required: true, doc: "Options to be passed to `Sanity.request/2`."
  }

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

  @sync_opts_schema [
    @callback_opt_schema,
    @request_opts_opt_schema
  ]

  @doc """
  Fetches a single document from Sanity. If the document exists then `upsert_sanity_doc!/2` will
  be called. If the document doesn't exist, then the `Sanity.Sync.Doc` for that document will be
  deleted.

  ## Options

  #{NimbleOptions.docs(@sync_opts_schema)}
  """
  def sync(id, opts) when is_binary(id) do
    opts = NimbleOptions.validate!(opts, @sync_opts_schema)

    stream(
      batch_size: 1,
      query: "_id == $id",
      request_opts: Keyword.fetch(opts, :request_opts),
      variables: %{id: id}
    )
    |> Enum.take(1)
    |> case do
      [doc] ->
        doc
        |> unsafe_atomize_keys(&Inflex.underscore/1)
        |> upsert_sanity_doc!(Keyword.take(opts, [:callback]))

      [] ->
        repo().delete_all(from d in Doc, where: d.id == ^id)
    end
  end

  @sync_all_opts_schema [
    @callback_opt_schema,
    @request_opts_opt_schema,
    types: [
      type: {:list, :string},
      required: true,
      doc: "List of types to sync."
    ]
  ]

  @doc """
  Fetches all documents from Sanity and calls `upsert_sanity_doc!/2`.

  ## Options

  #{NimbleOptions.docs(@sync_all_opts_schema)}
  """
  def sync_all(opts) do
    opts = NimbleOptions.validate!(opts, @sync_all_opts_schema)

    stream(
      query: "_type in $types",
      variables: %{types: Keyword.fetch!(opts, :types)},
      request_opts: Keyword.fetch!(opts, :request_opts)
    )
    |> Stream.each(&upsert_sanity_doc!(&1, Keyword.take(opts, [:callback])))
    |> Stream.run()
  end

  @upsert_sanity_doc_opts_schema [@callback_opt_schema]

  @doc """
  Upserts a sanity document.

  ## Options

  #{NimbleOptions.docs(@upsert_sanity_doc_opts_schema)}
  """
  def upsert_sanity_doc!(%{_id: id, _type: type} = doc, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @upsert_sanity_doc_opts_schema)

    Doc.changeset(%Doc{}, %{doc: doc, id: id, type: type})
    |> repo().insert!(conflict_target: :id, on_conflict: :replace_all)
    |> tap(fn _ ->
      case Keyword.fetch(opts, :callback) do
        {:ok, cb} -> cb.(%{doc: doc, repo: repo()})
        :error -> nil
      end
    end)
  end

  defp stream(opts) do
    Application.get_env(:sanity_sync, :sanity_client, Sanity).stream(opts)
    |> Stream.map(fn doc -> unsafe_atomize_keys(doc, &Inflex.underscore/1) end)
  end
end
