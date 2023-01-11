defmodule Sanity.Sync do
  @moduledoc """
  For syncing content from Sanity CMS to Ecto.

  ## Suggested strategy for syncing

  * Call `sync/2` when a webhook is called to immediately create, update, or delete the document.
  * Use `sync_all/1` for the inital import of documents and to reconcile created/updates webhooks
    that were missed.
  * Use `reconcile_deleted/1` to reconcile any deleted webhooks that were missed.
  """

  require Logger
  import Ecto.Query
  alias Sanity.Sync.Doc
  import UnsafeAtomizeKeys

  @callback_opt_schema {
    :callback,
    type: {:fun, 1},
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

  @reconcile_deleted_opts_schema [
    @request_opts_opt_schema,
    batch_size: [
      type: :pos_integer,
      default: 200,
      doc: "Number of records to fetch per batch."
    ]
  ]

  @doc """
  Deletes any `Sanity.Sync.Doc` records in Ecto that correspond with documents that no longer
  exist in Sanity CMS.

  ## Options

  #{NimbleOptions.docs(@reconcile_deleted_opts_schema)}
  """
  def reconcile_deleted(opts) do
    opts = NimbleOptions.validate!(opts, @reconcile_deleted_opts_schema)
    batch_size = opts[:batch_size]

    stream_ecto_ids(batch_size)
    |> Stream.chunk_every(batch_size)
    |> Enum.flat_map(fn ids ->
      existing_ids =
        stream(
          projection: "{ _id }",
          query: "_id in $ids",
          request_opts: opts[:request_opts],
          variables: %{ids: ids}
        )
        |> Enum.map(& &1._id)

      ids -- existing_ids
    end)
    |> case do
      [] ->
        nil

      ids ->
        Logger.warn("deleting #{length(ids)} records: #{inspect(ids, limit: :infinity)}")
        repo().delete_all(from d in Doc, where: d.id in ^ids)
    end
  end

  # Returns a lazy stream of all `Sanity.Sync.Doc` ids in Ecto. Like `Ecto.Repo.stream` but
  # doesn't keep a transaction open while enumerating.
  defp stream_ecto_ids(batch_size) do
    query =
      from d in Doc,
        select: d.id,
        order_by: d.id,
        limit: ^batch_size

    Stream.unfold(:first_page, fn
      nil ->
        nil

      :first_page ->
        ids = repo().all(query)
        {ids, List.last(ids)}

      last_id ->
        ids = repo().all(from d in query, where: d.id > ^last_id)
        {ids, List.last(ids)}
    end)
    |> Stream.flat_map(& &1)
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
      request_opts: opts[:request_opts],
      variables: %{id: id}
    )
    |> Enum.take(1)
    |> case do
      [doc] ->
        upsert_sanity_doc!(doc, Keyword.take(opts, [:callback]))

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
      variables: %{types: opts[:types]},
      request_opts: opts[:request_opts]
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
