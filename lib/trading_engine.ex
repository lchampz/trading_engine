defmodule TradingEngine do
  use GenServer

  def hello, do: :world

  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, opts)
  end

  def submit_order(server \\ __MODULE__, order), do: GenServer.call(server, {:submit_order, order})

  def book(server \\ __MODULE__), do: GenServer.call(server, :book)

  def history(server \\ __MODULE__), do: GenServer.call(server, :history)

  @spec init(any()) :: {:ok, any()}
  def init(_opts) do
    {:ok, OrderBook.new()}
  end

  def handle_call(:book, _from, state), do: {:reply, state, state}

  def handle_call(:history, _from, state), do: {:reply, state.history, state}

  def handle_call({:submit_order, order}, _from, state) do
    updated_state = OrderBook.apply_order(state, order)
    {:reply, {:ok, updated_state}, updated_state}
  end
end
