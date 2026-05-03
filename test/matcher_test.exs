defmodule MatcherTest do
  use ExUnit.Case, async: true

  describe "match_order/2" do
    test "returns the original order when there are no opposing orders" do
      buy_order = Order.new("buy-1", "100.00", 10, :buy)

      assert {updated_buy, updated_sells} = Matcher.match_order(buy_order, [])

      assert updated_buy == buy_order
      assert updated_sells == []
    end

    test "does not cross when the buy price is below the best sell" do
      buy_order = Order.new("buy-1", "95.00", 10, :buy)
      sell_order = Order.new("sell-1", "100.00", 8, :sell)

      assert {updated_buy, updated_sells} = Matcher.match_order(buy_order, [sell_order])

      assert updated_buy == buy_order
      assert updated_sells == [sell_order]
    end

    test "consumes a smaller sell order and keeps the remaining buy quantity" do
      buy_order = Order.new("buy-1", "100.00", 10, :buy)
      sell_order = Order.new("sell-1", "99.00", 4, :sell)

      assert {updated_buy, updated_sells} = Matcher.match_order(buy_order, [sell_order])

      assert updated_buy.quantity == 6
      assert updated_buy.price == buy_order.price
      assert updated_sells == []
    end

    test "consumes the buy order and preserves the residual sell quantity" do
      buy_order = Order.new("buy-1", "100.00", 4, :buy)
      sell_order = Order.new("sell-1", "99.00", 10, :sell)

      assert {updated_buy, updated_sells} = Matcher.match_order(buy_order, [sell_order])

      assert updated_buy.quantity == 0
      assert updated_buy.price == buy_order.price
      assert [%{quantity: 6}] = updated_sells
    end

    test "continues matching across multiple sell orders until the buy is exhausted" do
      buy_order = Order.new("buy-1", "100.00", 9, :buy)
      first_sell = Order.new("sell-1", "99.00", 3, :sell)
      second_sell = Order.new("sell-2", "98.00", 4, :sell)
      third_sell = Order.new("sell-3", "97.00", 8, :sell)

      assert {updated_buy, updated_sells} =
               Matcher.match_order(buy_order, [first_sell, second_sell, third_sell])

      assert updated_buy.quantity == 2
      assert updated_sells == [third_sell]
    end
  end
end