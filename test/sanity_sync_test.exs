defmodule SanitySyncTest do
  use SanitySync.DataCase, async: true
  doctest SanitySync, import: true

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
    assert %SanitySync.Doc{id: "6d30d4be-e90d-4738-80b2-0d57873cf4fc"} =
             SanitySync.upsert_sanity_doc!(@sanity_doc)

    assert SanitySync.get_doc!("6d30d4be-e90d-4738-80b2-0d57873cf4fc") == @sanity_doc
  end

  test "get_doc! not found" do
    assert_raise Ecto.NoResultsError, fn -> SanitySync.get_doc!("abd-def") end
  end

  test "sync_all" do
    # FIXME
  end

  test "sync_all invalid options" do
    assert_raise ArgumentError,
                 "unknown keys [:a] in [a: \"b\"], the allowed keys are: [:sanity_config, :types]",
                 fn ->
                   SanitySync.sync_all(a: "b")
                 end
  end

  test "upsert_sanity_doc!" do
    # Insert
    assert %SanitySync.Doc{id: "6d30d4be-e90d-4738-80b2-0d57873cf4fc"} =
             SanitySync.upsert_sanity_doc!(@sanity_doc)

    assert SanitySync.get_doc!("6d30d4be-e90d-4738-80b2-0d57873cf4fc").title == "Test Page"

    # Update
    new_doc = %{@sanity_doc | title: "new title"}

    assert %SanitySync.Doc{id: "6d30d4be-e90d-4738-80b2-0d57873cf4fc"} =
             SanitySync.upsert_sanity_doc!(new_doc)

    assert SanitySync.get_doc!("6d30d4be-e90d-4738-80b2-0d57873cf4fc").title == "new title"
  end
end
