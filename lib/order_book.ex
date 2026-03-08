defmodule OrderBook do
  defstruct [:buy_orders, :sell_orders, :history]

  use GenServer

  def start_link(), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  def init(), do: {:ok, %__MODULE__{buy_orders: [], sell_orders: [], history: []}}


  defp match_result({updated_sells}, state), do: save(:sell, updated_sells, state)

  defp sort(:buy, list, new), do: sort(list, new, :desc)
  defp sort(:sell, list, new), do: sort(list, new, :asc)
  defp sort(list, new_item, direction), do: [new_item | list] |> Enum.sort_by(fn order -> order.price end, direction)

  defp save(:buy, new, state), do: %{state | buy_orders: sort(:buy, state.buy_orders, new)}
  defp save(:sell, new, state), do: %{state | sell_orders: sort(:sell, state.sell_orders, new)}

end
