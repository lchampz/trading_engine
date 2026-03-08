defmodule Matcher do

  def match_order(order, []), do: {order, []}
  def match_order(%{price: p_buy} = buy, [%{price: p_sell} | _] = sells) when p_buy < p_sell do
    {buy, sells}
  end
  @spec match_order(any(), nonempty_maybe_improper_list()) :: {any(), any()}
  def match_order(buy, [sell | remaining_sells]) do
    cond do
      buy.quantity > sell.quantity ->
        new_buy = %{buy | quantity: buy.quantity - sell.quantity}

        match_order(new_buy, remaining_sells)
      buy.quantity < sell.quantity ->
        remaining_sell = %{sell | quantity: sell.quantity - buy.quantity}

        {[remaining_sell | remaining_sells]}
      true -> {remaining_sells}
    end
  end
end
