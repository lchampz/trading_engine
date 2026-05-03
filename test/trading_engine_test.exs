defmodule TradingEngineTest do
  use ExUnit.Case, async: false

  describe "start_link/1" do
    test "keeps one process alive when it restarts after a crash" do
      Process.flag(:trap_exit, true)

      assert {:ok, pid} = apply(TradingEngine, :start_link, [[name: :trading_engine_restart_test]])

      on_exit(fn ->
        if Process.alive?(pid) do
          GenServer.stop(pid)
        end
      end)

      Process.exit(pid, :kill)

      refute Process.alive?(pid)

      assert {:ok, replacement_pid} =
               apply(TradingEngine, :start_link, [[name: :trading_engine_restart_test]])

      assert is_pid(replacement_pid)
      refute replacement_pid == pid
    end

    test "allows multiple instances with different names" do
      Process.flag(:trap_exit, true)

      assert {:ok, pid_a} = apply(TradingEngine, :start_link, [[name: :trading_engine_a]])

      on_exit(fn ->
        if Process.alive?(pid_a) do
          GenServer.stop(pid_a)
        end
      end)

      assert {:ok, pid_b} = apply(TradingEngine, :start_link, [[name: :trading_engine_b]])

      on_exit(fn ->
        if Process.alive?(pid_b) do
          GenServer.stop(pid_b)
        end
      end)

      assert pid_a != pid_b
      assert Process.alive?(pid_a)
      assert Process.alive?(pid_b)
    end
  end
end
