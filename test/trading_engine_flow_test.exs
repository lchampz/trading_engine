defmodule TradingEngineFlowTest do
  use ExUnit.Case, async: false

  describe "TradingEngine public flow" do
    test "submits orders, matches them and exposes book and history" do
      Process.flag(:trap_exit, true)

      {:ok, pid} = TradingEngine.start_link(name: :trading_engine_flow_test)

      on_exit(fn ->
        if Process.alive?(pid) do
          GenServer.stop(pid)
        end
      end)

      sell_order = Order.new("sell-1", "99.00", 4, :sell)
      buy_order = Order.new("buy-1", "100.00", 10, :buy)

      assert {:ok, %OrderBook{} = after_sell} = TradingEngine.submit_order(pid, sell_order)
      assert after_sell.sell_orders == [sell_order]
      assert after_sell.buy_orders == []
      assert after_sell.history == [sell_order]

      assert {:ok, %OrderBook{} = after_buy} = TradingEngine.submit_order(pid, buy_order)
      assert after_buy.buy_orders == [%{buy_order | quantity: 6}]
      assert after_buy.sell_orders == []
      assert after_buy.history == [sell_order, buy_order]

      assert %OrderBook{buy_orders: [%{quantity: 6}], sell_orders: [], history: [^sell_order, ^buy_order]} =
               TradingEngine.book(pid)

      assert TradingEngine.history(pid) == [sell_order, buy_order]
    end
  end
end