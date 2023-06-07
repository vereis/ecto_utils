defmodule EctoUtils.Schema do
  @moduledoc """
  Utility module containing functions which aim to augment modules that `use Ecto.Schema`
  """

  import Ecto.Query

  @doc """
  Allows you to execute any `EctoUtils.Schema` function in the module that `use`-es this
  macro.

  This is useful for building a custom `MyApp.Schema` module that you use rather than the default
  `Ecto.Schema`, allowing for convenient extension capabilities, building off of `EctoUtils`'s
  extended base functionality.

  Usage:

  ```elixir
  defmodule MyApp.Schema do
    use Ecto.Schema
    use EctoUtils.Schema, repo: MyApp.Repo
  end
  ```
  """
  defmacro __using__(opts) do
    repo = Keyword.get(opts, :repo)

    unless match?({:__aliases__, _, _}, repo) or is_atom(repo) do
      raise ArgumentError,
        message: "Option `repo` must be provided, pointing to your applications Ecto Repo."
    end

    schema = __MODULE__
    functions = schema.__info__(:functions)

    delegates =
      for {function, arity} <- functions do
        arguments = Macro.generate_arguments(arity, __MODULE__)

        quote do
          defdelegate unquote(function)(unquote_splicing(arguments)),
            to: unquote(schema)
        end
      end

    [
      quote do
        import unquote(__MODULE__)

        @doc """
        Helper function for handling the boilerplate of preloading associations before setting them
        as an association, particularly useful for many-to-many or has-many relations.
        """
        @spec preload_put_assoc(Ecto.Changeset.t(), attrs :: map(), field :: atom()) ::
                Ecto.Changeset.t()
        def preload_put_assoc(changeset, attrs, field, attr_key \\ nil, filters \\ [])

        def preload_put_assoc(%Ecto.Changeset{} = changeset, attrs, field, attr_key, filters) do
          unquote(schema).preload_put_assoc(
            unquote(repo),
            changeset,
            attrs,
            field,
            attr_key || field,
            filters
          )
        end

        @doc """
        Helper function for returning a list of valid fields for this schema. Useful for casting changeset
        attrs.
        """
        @spec fields :: [atom()]
        def fields, do: __schema__(:fields)

        @doc """
        Helper function for returning a list of valid associations (`belongs_to`, `has_one`, `has_many`, or
        `many_to_many` fields) for this schema.
        """
        @spec associations :: [atom()]
        def associations, do: __schema__(:associations)

        @doc """
        Helper function for looking up metadata about a specific association for this schema.
        """
        @spec association(atom()) :: Ecto.Association.t()
        def association(field), do: __schema__(:association, field)
      end
      | delegates
    ]
  end

  defmacro join_schema(table, {from_id, to_id}) when is_binary(table) do
    module = Module.concat([EctoUtils.Dyn.JoinSchemas, __CALLER__.module, Macro.camelize(table)])

    module_declaration =
      quote bind_quoted: binding() do
        defmodule module do
          use Ecto.Schema

          @primary_key false
          schema table do
            field(from_id, :id)
            field(to_id, :id)
            timestamps()
          end
        end
      end

    quote bind_quoted: binding(), location: :keep do
      {:module, _name, _bytecode, _env} = module_declaration
      module
    end
  end

  @doc """
  Helper function for handling the boilerplate of preloading associations before setting them
  as an association, particularly useful for many-to-many or has-many relations.
  """
  @spec preload_put_assoc(
          repo :: module(),
          Ecto.Changeset.t(),
          attrs :: map(),
          field :: atom(),
          attr_key :: atom(),
          filters :: Keyword.t()
        ) ::
          Ecto.Changeset.t()
  def preload_put_assoc(repo, changeset, attrs, field, attr_key, filters \\ [])

  def preload_put_assoc(repo, %Ecto.Changeset{} = changeset, attrs, field, attr_key, filters) do
    case Map.get(attrs, attr_key) do
      nil ->
        changeset

      item ->
        items = handle_preload_put_assoc_items(repo, changeset, field, item, filters)

        changeset
        |> Map.fetch!(:data)
        |> repo.preload(field)
        |> then(fn data -> %Ecto.Changeset{changeset | data: data} end)
        |> Ecto.Changeset.put_assoc(field, items)
    end
  end

  defp handle_preload_put_assoc_items(
         repo,
         %Ecto.Changeset{data: %schema{}},
         field,
         items,
         filters
       ) do
    queryable =
      field
      |> schema.association()
      |> Map.get(:queryable)

    cond do
      Enum.all?(items, &is_struct(&1, queryable)) ->
        items

      Enum.all?(items, &is_binary/1) ->
        items = Enum.map(items, &String.to_integer/1)
        repo.all(from(x in queryable, where: x.id in ^items, where: ^filters))

      Enum.all?(items, &is_integer/1) ->
        repo.all(from(x in queryable, where: x.id in ^items, where: ^filters))

      true ->
        raise "Function `preload_put_assoc/3` expects items to either be a list of IDs, or a list of structs, got: #{inspect(items)}"
    end
  end

  @doc """
  Ecto sanitizes inputs passed in via attrs such that trying to cast a field to `nil` will
  be determined to be a no-op and will silently fail.

  This function lets you explicitly mark fields where `nil` casts are valid, and will perform
  them for you.

  Use as follows:
  ```elixir
  def changeset(%MyApp.User{} = struct, attrs) do
    struct
    |> cast([:is_deleted])
    |> mark_nilable(params, :is_deleted)
  end

  # When called as `changeset(%MyApp.User{is_deleted: true}, %{is_deleted: nil}})`, will return
  # a changeset containing the `is_deleted: nil` change, where without using this function,
  # no change would be detected.
  ```
  """
  @spec mark_nilable(Ecto.Changeset.t(), params :: map(), field :: atom()) :: Ecto.Changeset.t()
  def mark_nilable(%Ecto.Changeset{} = changeset, params, field) do
    (params[field] in [0, nil] && Ecto.Changeset.force_change(changeset, field, nil)) || changeset
  end
end
