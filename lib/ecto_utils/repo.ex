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
end
