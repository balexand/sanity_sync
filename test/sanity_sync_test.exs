defmodule SanitySyncTest do
  use SanitySync.DataCase, async: true
  doctest SanitySync

  test "greets the world" do
    assert SanitySync.hello() == :world
  end
end
