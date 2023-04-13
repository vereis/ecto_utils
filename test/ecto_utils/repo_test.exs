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

  describe "__using__/1" do
    defmodule Repo do
      use Ecto.Repo,
        otp_app: :ecto_utils,
        adapter: Etso.Adapter

      use EctoUtils.Repo
    end

    defmodule VanillaRepo do
      use Ecto.Repo,
        otp_app: :ecto_utils,
        adapter: Etso.Adapter
    end

    for {function, arity} <- [schema?: 1, preloads: 1] do
      test "`#{function}/#{arity}` is injected into Repo" do
        assert function_exported?(Repo, unquote(function), unquote(arity))
      end

      test "`#{function}/#{arity}` is not exported in vanilla Repo" do
        refute function_exported?(VanillaRepo, unquote(function), unquote(arity))
      end
    end
  end

  describe "preloads/1" do
    test "returns empty list given schema with no associations" do
      assert [] = Repo.preloads(%Cucumber{})
    end

    test "returns empty list given schema with associations, but nothing preloaded" do
      assert [] = Repo.preloads(%Jar{})
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
               Repo.preloads(jar)
    end

    test "raises when given anything that isn't a struct from a module that `use`-es `Ecto.Schema`" do
      assert_raise ArgumentError, fn -> Repo.preloads(Date.utc_today()) end
    end
  end

  describe "schema?/1" do
    test "returns true if given module that `use`-es `Ecto.Schema`" do
      assert Repo.schema?(Cucumber)
    end

    test "returns true if given struct of module that `use`-es `Ecto.Schema`" do
      assert Repo.schema?(%Cucumber{})
    end

    test "returns false if given random atom" do
      refute Repo.schema?(:atom)
    end

    test "returns false if given module that does not `use` `Ecto.Schema`" do
      refute Repo.schema?(Date)
    end

    test "returns false if given struct of module that does not `use` `Ecto.Schema`" do
      refute Repo.schema?(Date.utc_today())
    end

    test "raises given anything else" do
      assert_raise FunctionClauseError, fn -> Repo.schema?("test") end
    end
  end
end
