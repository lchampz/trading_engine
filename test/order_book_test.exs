defmodule OrderBookTest do
  use ExUnit.Case, async: false

  describe "init/0" do
    test "starts with empty buy, sell and history collections" do
      assert {:ok, %OrderBook{buy_orders: [], sell_orders: [], history: []}} = OrderBook.init()
    end
  end

  describe "start_link/1" do
    test "can be started as a GenServer instance" do
      assert {:ok, pid} = OrderBook.start_link()

      on_exit(fn ->
        if Process.alive?(pid) do
          GenServer.stop(pid)
        end
      end)

      assert Process.alive?(pid)
      assert %OrderBook{buy_orders: [], sell_orders: [], history: []} = :sys.get_state(pid)
    end
  end
end