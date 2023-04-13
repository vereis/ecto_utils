defmodule EctoUtils.Queryable do
  @moduledoc """
  Exposes the queryable behaviour and utility macro for making Ecto Query composition
  for Ecto Schemas easier to define, isolate, and be consistent.
  """

  import Ecto.Query

  defmacro __using__(_opts) do
    quote do
      import Ecto.Query

      @behaviour unquote(__MODULE__)

      @impl unquote(__MODULE__)
      def base_query, do: from(x in __MODULE__, as: :self)
      defoverridable(base_query: 0)
    end
  end

  @callback query(Ecto.Queryable.t(), Keyword.t()) :: Ecto.Queryable.t()
  @callback base_query() :: Ecto.Queryable.t()
  @optional_callbacks base_query: 0

  @doc "Returns true if, and only if, the given module implements the #{inspect(__MODULE__)} behaviour"
  @spec implemented_by?(module()) :: boolean()
  def implemented_by?(module) when is_atom(module) do
    behaviours =
      module.module_info(:attributes)
      |> Enum.filter(&match?({:behaviour, _behaviours}, &1))
      |> Enum.map(&elem(&1, 1))
      |> List.flatten()

    __MODULE__ in behaviours
  end

  @doc """
  Generic fallback filters for the `EctoUtils.Queryable` behaviour. Schemas which implement the
  `query/2` callback are able to add a catch-all fallback clause pointing to this function in order
  to allow `EctoUtils` to automatically derive common queries.

  Usage:
  ```elixir
  @impl EctoUtils.Queryable
  def query(base_query \\ base_query(), filters) do
    Enum.reduce(filters, query, fn
      {:inserted_at_start, datetime}, query ->
        from(x in query, where: x.inserted_at >= ^datetime)

      {:inserted_at_end, datetime}, query ->
        from(x in query, where: x.inserted_at <= ^datetime)

      {:updated_at_start, datetime}, query ->
        from(x in query, where: x.updated_at >= ^datetime)

      {:updated_at_end, datetime}, query ->
        from(x in query, where: x.updated_at <= ^datetime)

      {field, value}, query ->
        apply_filter(query, field, value)
    end)
  end
  ```
  """
  @spec apply_filter(module | Ecto.Queryable.t(), field :: atom(), value :: term()) ::
          Ecto.Queryable.t()
  def apply_filter(query, :preload, value) do
    from(x in query, preload: ^value)
  end

  def apply_filter(query, :limit, value) do
    from(x in query, limit: ^value)
  end

  def apply_filter(query, :offset, value) do
    from(x in query, offset: ^value)
  end

  def apply_filter(query, :order_by, value) when is_list(value) do
    from(x in query, order_by: ^value)
  end

  def apply_filter(query, :order_by, {direction, value}) do
    from(x in query, order_by: [{^direction, ^value}])
  end

  def apply_filter(query, :order_by, value) do
    from(x in query, order_by: [{:desc, ^value}])
  end

  def apply_filter(query, field, value) when is_list(value) do
    from(x in query, where: field(x, ^field) in ^value)
  end

  def apply_filter(query, field, value) do
    from(x in query, where: field(x, ^field) == ^value)
  end
end
