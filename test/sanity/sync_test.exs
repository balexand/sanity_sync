defmodule Sanity.SyncTest do
  use Sanity.Sync.DataCase, async: true
  doctest Sanity.Sync, import: true

  import Mox
  setup :verify_on_exit!

  import ExUnit.CaptureLog
  alias Sanity.Sync.{MockCallback, MockClient}

  @id "6d30d4be-e90d-4738-80b2-0d57873cf4fc"

  @sanity_doc %{
    _createdAt: "2022-09-13T21:52:07Z",
    _id: @id,
    _rev: "UbpbTThmASTgUkCXeTdqjx",
    _type: "page",
    _updatedAt: "2022-09-13T21:52:07Z",
    path: %{_type: "slug", current: "/test"},
    title: "Test Page"
  }

  defp doc_fixture(doc_attrs \\ %{}) do
    assert %Sanity.Sync.Doc{} = Sanity.Sync.upsert_sanity_doc!(Map.merge(@sanity_doc, doc_attrs))
  end

  test "get_doc" do
    assert nil == Sanity.Sync.get_doc("abc-def")

    doc_fixture()
    assert Sanity.Sync.get_doc(@id) == @sanity_doc
  end

  test "get_doc!" do
    doc_fixture()

    assert Sanity.Sync.get_doc!(@id) == @sanity_doc
  end

  test "get_doc! not found" do
    assert_raise Ecto.NoResultsError, fn -> Sanity.Sync.get_doc!("abd-def") end
  end

  test "reconcile_deleted" do
    doc_fixture()
    doc_fixture(%{_id: "other"})

    Sanity.Sync.get_doc!(@id)
    Sanity.Sync.get_doc!("other")

    Mox.expect(MockClient, :stream, fn _opts ->
      [%{"_id" => @id}]
    end)

    log =
      capture_log([level: :warn], fn ->
        Sanity.Sync.reconcile_deleted(request_opts: [project_id: "a"])
      end)

    assert log =~ ~S'deleting 1 records: ["other"]'

    Sanity.Sync.get_doc!(@id)
    assert Sanity.Sync.get_doc("other") == nil
  end

  test "sync" do
    assert nil == Sanity.Sync.get_doc(@id)

    Mox.expect(MockClient, :stream, fn _opts -> [@sanity_doc] end)
    Mox.expect(MockCallback, :callback, fn %{doc: @sanity_doc, repo: _} -> nil end)

    Sanity.Sync.sync(@id, callback: &MockCallback.callback/1, request_opts: [project_id: "a"])

    assert @sanity_doc == Sanity.Sync.get_doc(@id)

    # deletes document
    Mox.expect(MockClient, :stream, fn _opts -> [] end)

    Sanity.Sync.sync(@id, callback: &MockCallback.callback/1, request_opts: [project_id: "a"])

    assert nil == Sanity.Sync.get_doc(@id)
  end

  test "sync_all" do
    Mox.expect(MockClient, :stream, fn opts ->
      assert opts == [
               query: "_type in $types",
               variables: %{types: ["page", "product"]},
               request_opts: [project_id: "a"]
             ]

      [@sanity_doc]
    end)

    assert nil == Sanity.Sync.get_doc(@id)

    Sanity.Sync.sync_all(types: ["page", "product"], request_opts: [project_id: "a"])

    assert @sanity_doc == Sanity.Sync.get_doc(@id)
  end

  test "sync_all with callback" do
    Mox.expect(MockClient, :stream, fn _opts -> [@sanity_doc] end)
    Mox.expect(MockCallback, :callback, fn %{doc: @sanity_doc, repo: _} -> nil end)

    Sanity.Sync.sync_all(
      callback: &MockCallback.callback/1,
      types: ["page", "product"],
      request_opts: []
    )

    assert @sanity_doc == Sanity.Sync.get_doc(@id)
  end

  test "sync_all invalid options" do
    assert_raise NimbleOptions.ValidationError, ~R{unknown options \[:a\]}, fn ->
      Sanity.Sync.sync_all(a: "b")
    end
  end

  test "upsert_sanity_doc!" do
    # Insert
    assert %Sanity.Sync.Doc{id: "6d30d4be-e90d-4738-80b2-0d57873cf4fc"} =
             Sanity.Sync.upsert_sanity_doc!(@sanity_doc)

    assert Sanity.Sync.get_doc!("6d30d4be-e90d-4738-80b2-0d57873cf4fc").title == "Test Page"

    # Update
    new_doc = %{@sanity_doc | title: "new title"}

    assert %Sanity.Sync.Doc{id: "6d30d4be-e90d-4738-80b2-0d57873cf4fc"} =
             Sanity.Sync.upsert_sanity_doc!(new_doc)

    assert Sanity.Sync.get_doc!("6d30d4be-e90d-4738-80b2-0d57873cf4fc").title == "new title"
  end
end
