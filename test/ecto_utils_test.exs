defmodule EctoUtilsTest do
  use ExUnit.Case
  doctest EctoUtils

  test "greets the world" do
    assert EctoUtils.hello() == :world
  end
end
