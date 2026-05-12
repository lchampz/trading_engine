defmodule Matcher do
  def match_order(order, []), do: {order, []}

  def match_order(%{side: :buy} = buy, [%{price: best_sell_price} | _] = sells) do
    if Decimal.compare(buy.price, best_sell_price) == :lt do
      {buy, sells}
    else
      match_buy(buy, sells)
    end
  end

  def match_order(%{side: :sell} = sell, [%{price: best_buy_price} | _] = buys) do
    if Decimal.compare(sell.price, best_buy_price) == :gt do
      {sell, buys}
    else
      match_sell(sell, buys)
    end
  end

  defp match_buy(buy, sells), do: match_buy(buy, sells, false)

  defp match_buy(buy, [], _matched_any), do: {buy, []}

  defp match_buy(buy, [sell | remaining_sells], matched_any) do
    cond do
      buy.quantity > sell.quantity ->
        updated_buy = %{buy | quantity: buy.quantity - sell.quantity}
        match_buy(updated_buy, remaining_sells, true)

      buy.quantity < sell.quantity ->
        if matched_any do
          {buy, [sell | remaining_sells]}
        else
          remaining_sell = %{sell | quantity: sell.quantity - buy.quantity}
          {%{buy | quantity: 0}, [remaining_sell | remaining_sells]}
        end

      true ->
        {%{buy | quantity: 0}, remaining_sells}
    end
  end

  defp match_sell(sell, buys), do: match_sell(sell, buys, false)

  defp match_sell(sell, [], _matched_any), do: {sell, []}

  defp match_sell(sell, [buy | remaining_buys], matched_any) do
    cond do
      sell.quantity > buy.quantity ->
        updated_sell = %{sell | quantity: sell.quantity - buy.quantity}
        match_sell(updated_sell, remaining_buys, true)

      sell.quantity < buy.quantity ->
        if matched_any do
          {sell, [buy | remaining_buys]}
        else
          remaining_buy = %{buy | quantity: buy.quantity - sell.quantity}
          {%{sell | quantity: 0}, [remaining_buy | remaining_buys]}
        end

      true ->
        {%{sell | quantity: 0}, remaining_buys}
    end
  end
end
