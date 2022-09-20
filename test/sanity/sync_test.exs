defmodule Sanity.SyncTest do
  use Sanity.Sync.DataCase, async: true
  doctest Sanity.Sync, import: true

  import Mox
  setup :verify_on_exit!

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

  defp doc_fixture do
    assert %Sanity.Sync.Doc{id: @id} = Sanity.Sync.upsert_sanity_doc!(@sanity_doc)
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

  test "sync" do
    assert nil == Sanity.Sync.get_doc(@id)

    Mox.expect(MockClient, :request!, fn %Sanity.Request{}, _ ->
      %Sanity.Response{body: %{"result" => [@sanity_doc]}}
    end)

    Mox.expect(MockCallback, :callback, fn %{doc: @sanity_doc, repo: _} -> nil end)

    Sanity.Sync.sync(@id, callback: &MockCallback.callback/1, sanity_config: [project_id: "a"])

    assert @sanity_doc == Sanity.Sync.get_doc(@id)

    # deletes document
    Mox.expect(MockClient, :request!, fn %Sanity.Request{}, _ ->
      %Sanity.Response{body: %{"result" => []}}
    end)

    Sanity.Sync.sync(@id, callback: &MockCallback.callback/1, sanity_config: [project_id: "a"])

    assert nil == Sanity.Sync.get_doc(@id)
  end

  test "sync_all" do
    Mox.expect(MockClient, :request!, fn %Sanity.Request{}, [project_id: "a"] ->
      %Sanity.Response{body: %{"result" => [@sanity_doc]}}
    end)

    assert nil == Sanity.Sync.get_doc(@id)

    Sanity.Sync.sync_all(types: ["page", "product"], sanity_config: [project_id: "a"])

    assert @sanity_doc == Sanity.Sync.get_doc(@id)
  end

  test "sync_all with callback" do
    Mox.expect(MockClient, :request!, fn _, _ ->
      %Sanity.Response{body: %{"result" => [@sanity_doc]}}
    end)

    Mox.expect(MockCallback, :callback, fn %{doc: @sanity_doc, repo: _} -> nil end)

    Sanity.Sync.sync_all(
      callback: &MockCallback.callback/1,
      types: ["page", "product"],
      sanity_config: []
    )

    assert @sanity_doc == Sanity.Sync.get_doc(@id)
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
