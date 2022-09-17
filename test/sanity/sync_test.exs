defmodule Sanity.SyncTest do
  use Sanity.Sync.DataCase, async: true
  doctest Sanity.Sync, import: true

  @sanity_doc %{
    _createdAt: "2022-09-13T21:52:07Z",
    _id: "6d30d4be-e90d-4738-80b2-0d57873cf4fc",
    _rev: "UbpbTThmASTgUkCXeTdqjx",
    _type: "page",
    _updatedAt: "2022-09-13T21:52:07Z",
    path: %{_type: "slug", current: "/test"},
    title: "Test Page"
  }

  test "get_doc!" do
    assert %Sanity.Sync.Doc{id: "6d30d4be-e90d-4738-80b2-0d57873cf4fc"} =
             Sanity.Sync.upsert_sanity_doc!(@sanity_doc)

    assert Sanity.Sync.get_doc!("6d30d4be-e90d-4738-80b2-0d57873cf4fc") == @sanity_doc
  end

  test "get_doc! not found" do
    assert_raise Ecto.NoResultsError, fn -> Sanity.Sync.get_doc!("abd-def") end
  end

  test "sync_all" do
    # FIXME
  end

  test "sync_all invalid options" do
    assert_raise ArgumentError,
                 "unknown keys [:a] in [a: \"b\"], the allowed keys are: [:callback, :sanity_config, :types]",
                 fn ->
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
