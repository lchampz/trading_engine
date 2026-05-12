defmodule OrderBook do
  defstruct [:buy_orders, :sell_orders, :history]

  use GenServer

  def new, do: %__MODULE__{buy_orders: [], sell_orders: [], history: []}

  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, opts)
  end

  def init(), do: {:ok, new()}

  def init(_opts), do: init()

  def submit_order(server \\ __MODULE__, order), do: GenServer.call(server, {:submit_order, order})

  def snapshot(server \\ __MODULE__), do: GenServer.call(server, :snapshot)

  def apply_order(state, %{side: :buy} = order) do
    {updated_buy, updated_sells} = Matcher.match_order(order, state.sell_orders)

    state =
      state
      |> Map.put(:sell_orders, updated_sells)
      |> append_history(order)

    if updated_buy.quantity > 0 do
      %{state | buy_orders: insert_order(state.buy_orders, updated_buy, :buy)}
    else
      state
    end
  end

  def apply_order(state, %{side: :sell} = order) do
    {updated_sell, updated_buys} = Matcher.match_order(order, state.buy_orders)

    state =
      state
      |> Map.put(:buy_orders, updated_buys)
      |> append_history(order)

    if updated_sell.quantity > 0 do
      %{state | sell_orders: insert_order(state.sell_orders, updated_sell, :sell)}
    else
      state
    end
  end

  def handle_call(:snapshot, _from, state), do: {:reply, state, state}

  def handle_call({:submit_order, order}, _from, state) do
    updated_state = apply_order(state, order)
    {:reply, {:ok, updated_state}, updated_state}
  end
  defp sort(:buy, list, new), do: sort(list, new, :desc)
  defp sort(:sell, list, new), do: sort(list, new, :asc)
  defp sort(list, new_item, direction), do: [new_item | list] |> Enum.sort_by(fn order -> order.price end, direction)

  defp insert_order(list, order, side), do: sort(side, list, order)

  defp append_history(state, order), do: %{state | history: state.history ++ [order]}

end
