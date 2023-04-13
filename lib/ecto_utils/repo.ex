defmodule EctoUtils.Repo do
  @moduledoc """
  Utility module containing functions which aim to augment modules that `use Ecto.Repo`
  """

  @doc """
  Allows you to execute any `EctoUtils.Repo` function in the module that `use`-es this
  macro.

  This is useful for centralizing Repo functions in your app's own repo module, rather
  than you needing to manually call `EctoUtils.Repo` functions yourself.

  Usage:

  ```elixir
  defmodule MyApp.Repo do
    use Ecto.Repo, ...
    use EctoUtils.Repo
  end

  MyApp.Repo.schema?(Date.utc_today())
  > false
  ```
  """
  defmacro __using__(_opts) do
    repo = __MODULE__
    functions = repo.__info__(:functions)

    delegates =
      for {function, arity} <- functions do
        arguments = Macro.generate_arguments(arity, __MODULE__)

        quote do
          defdelegate unquote(function)(unquote_splicing(arguments)),
            to: unquote(repo)
        end
      end

    [
      quote do
        @doc """
        Executes the given closure in a transaction; returning its returns, but ensuring that the transaction
        was rolled back in the process.
        """
        @spec dry_run(closure :: (() -> term())) :: {:ok, term()} | {:error, term()}
        def dry_run(closure), do: dry_run(unquote(repo), closure)
      end
      | delegates
    ]
  end

  @doc """
  Executes the given closure in a transaction; returning its returns, but ensuring that the transaction
  was rolled back in the process.
  """
  @spec dry_run(repo :: module(), closure :: (() -> term())) :: {:ok, term()} | {:error, term()}
  def dry_run(repo, closure) when is_atom(repo) and is_function(closure, 0) do
    ref = make_ref()

    case repo.transaction(fn -> repo.rollback({ref, closure.()}) end) do
      {:error, {^ref, result}} ->
        {:ok, result}

      {:error, reason} ->
        {:error, reason}

      {:ok, unexpected_response} ->
        {:error, unexpected_response}

      unexpected_response ->
        {:error, unexpected_response}
    end
  end

  @doc """
  Returns true if the given paramter is an Elixir module that `use`-es `Ecto.Schema`
  or is a struct derived from a module that `use`-es `Ecto.Schema`
  """
  @spec schema?(module() | struct()) :: boolean()
  def schema?(module) when is_atom(module) do
    function_exported?(module, :__schema__, 2)
  end

  def schema?(%module{} = _struct) do
    schema?(module)
  end

  @doc """
  Given a struct derived from a module that `use`-es `Ecto.Schema`, returns the list
  of currently preloaded associations for said schema.

  This can be useful when used in conjunction with `Repo.reload/2` to refetch a given
  struct from the database while also reloading all preloads:

  ```elixir
  user = %MyApp.User{orgs: [...]}
  preloads = MyApp.Repo.preloads(user)

  user
  |> MyApp.Repo.reload()
  |> MyApp.Repo.preload(preloads)
  ```
  """
  @spec preloads(struct()) :: [atom()]
  def preloads(%module{} = record) do
    unless schema?(module) do
      raise ArgumentError,
        message: "Expected an Ecto schema struct, given: `%#{inspect(module)}{}`"
    end

    do_preloads(record)
  end

  defp do_preloads(%schema{} = record) when schema != Ecto.Association.NotLoaded do
    associations = schema.__schema__(:associations)

    record
    |> Map.from_struct()
    |> Enum.flat_map(fn {field, value} ->
      if not match?(%{__struct__: Ecto.Association.NotLoaded}, value) and field in associations do
        value
        |> do_preloads()
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

  defp do_preloads(_value), do: []
end
