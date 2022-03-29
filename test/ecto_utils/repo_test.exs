defmodule EctoUtils.RepoTest do
  use ExUnit.Case

  alias EctoUtils.Repo

  defmodule Cucumber do
    use Ecto.Schema

    schema "cucumbers" do
      field(:size, :integer)
    end
  end

  defmodule Jar do
    use Ecto.Schema

    schema "jar" do
      has_many(:cucumbers, EctoUtils.RepoTest.Cucumber)
      belongs_to(:parent_jar, __MODULE__)
    end
  end

  describe "list_preloads/1" do
    test "returns empty list given schema with no associations" do
      assert [] = Repo.list_preloads(%Cucumber{})
    end

    test "returns empty list given schema with associations, but nothing preloaded" do
      assert [] = Repo.list_preloads(%Jar{})
    end

    test "returns list of potentially nested preloaded fields on given schema" do
      cucumber = %Cucumber{}

      jar = %Jar{
        parent_jar: %Jar{
          cucumbers: [cucumber],
          parent_jar: %Jar{
            cucumbers: [cucumber, cucumber, cucumber],
            parent_jar: %Jar{cucumbers: []}
          }
        }
      }

      assert [parent_jar: [:cucumbers, parent_jar: [:cucumbers, parent_jar: [:cucumbers]]]] =
               Repo.list_preloads(jar)
    end

    test "raises when given anything that isn't a struct from a module that `use`-es `Ecto.Schema`" do
      assert_raise ArgumentError, fn -> Repo.list_preloads(Date.utc_today()) end
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
