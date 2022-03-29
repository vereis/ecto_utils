defmodule EctoUtils.Repo do
  @moduledoc """
  Utility module containing functions which aim to augment modules that `use Ecto.Repo`
  """

  @doc """
  Returns true if the given paramter is an Elixir module that `use`-es `Ecto.Schema`
  or is a struct derived from a module that `use`-es `Ecto.Schema`
  """
  @spec is_schema(module() | struct()) :: boolean()
  def is_schema(module) when is_atom(module) do
    function_exported?(module, :__schema__, 2)
  end

  def is_schema(%module{} = _struct) do
    is_schema(module)
  end

  @doc """
  Given a struct derived from a module that `use`-es `Ecto.Schema`, returns the list
  of currently preloaded associations for said schema.

  This can be useful when used in conjunction with `Repo.reload/2` to refetch a given
  struct from the database while also reloading all preloads:

  ```elixir
  user = %MyApp.User{orgs: [...]}
  preloads = MyApp.Repo.list_preloads(user)

  user
  |> MyApp.Repo.reload()
  |> MyApp.Repo.preload(preloads)
  ```
  """
  @spec list_preloads(struct()) :: [atom()]
  def list_preloads(%module{} = record) do
    unless is_schema(module) do
      raise ArgumentError,
        message: "Expected an Ecto schema struct, given: `%#{inspect(module)}{}`"
    end

    do_list_preloads(record)
  end

  defp do_list_preloads(%schema{} = record) when schema != Ecto.Association.NotLoaded do
    associations = schema.__schema__(:associations)

    record
    |> Map.from_struct()
    |> Enum.flat_map(fn {field, value} ->
      if not match?(%{__struct__: Ecto.Association.NotLoaded}, value) and field in associations do
        value
        |> do_list_preloads()
        |> case do
          [] ->
            [field]

          nested_fields ->
            [{field, nested_fields}]
        end
      else
        []
      end
    end)
  end

  defp do_list_preloads(_value), do: []
end
