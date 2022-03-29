defmodule EctoUtils.RepoTest do
  use ExUnit.Case

  alias EctoUtils.Repo

  defmodule Cucumber do
    use Ecto.Schema

    schema "cucumbers" do
      field(:size, :integer)
    end
  end

  describe "is_schema/1" do
    test "returns true if given module that `use`-es `Ecto.Schema`" do
      assert Repo.is_schema(Cucumber)
    end

    test "returns true if given struct of module that `use`-es `Ecto.Schema`" do
      assert Repo.is_schema(%Cucumber{})
    end

    test "returns false if given random atom" do
      refute Repo.is_schema(:atom)
    end

    test "returns false if given module that does not `use` `Ecto.Schema`" do
      refute Repo.is_schema(Date)
    end

    test "returns false if given struct of module that does not `use` `Ecto.Schema`" do
      refute Repo.is_schema(Date.utc_today())
    end

    test "raises given anything else" do
      assert_raise FunctionClauseError, fn -> Repo.is_schema("test") end
    end
  end
end
