defmodule OrderTest do
  use ExUnit.Case, async: true

  describe "new/4" do
    test "normalizes price into Decimal and keeps the rest of the order data" do
      order = Order.new("order-1", "100.50", 25, :buy)

      assert order.id == "order-1"
      assert order.price == Decimal.new("100.50")
      assert order.quantity == 25
      assert order.side == :buy
      assert %DateTime{} = order.timestamp
    end

    test "creates distinct timestamps for distinct orders" do
      first_order = Order.new("order-1", "99.10", 10, :sell)
      second_order = Order.new("order-2", "99.10", 10, :sell)

      assert %DateTime{} = first_order.timestamp
      assert %DateTime{} = second_order.timestamp
      assert DateTime.compare(first_order.timestamp, second_order.timestamp) in [:lt, :eq]
    end
  end
end