defmodule SanitySyncTest do
  use ExUnit.Case
  doctest SanitySync

  test "greets the world" do
    assert SanitySync.hello() == :world
  end
end
