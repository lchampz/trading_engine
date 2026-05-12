defmodule TradingEngine.Demo do
  use GenServer

  @default_nodes 5
  @default_speed 1.0
  @max_events 12
  @max_levels 5

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def start(opts \\ []), do: start_link(opts)

  def stop(server \\ __MODULE__), do: GenServer.stop(server)

  def init(opts) do
    Process.flag(:trap_exit, true)

    engine_name = normalize_engine_name(Keyword.get(opts, :engine_name, :trading_engine_demo))
    node_count = Keyword.get(opts, :nodes, @default_nodes)
    speed = Keyword.get(opts, :speed, @default_speed)
    render_interval = render_interval(speed)

    {:ok, _engine_pid} = TradingEngine.start_link(name: engine_name)

    nodes = build_nodes(node_count)
    dashboard_pid = self()

    node_pids =
      Enum.map(nodes, fn node ->
        Task.start_link(fn -> node_loop(node, dashboard_pid, engine_name, speed) end)
      end)

    state = %{
      engine_name: engine_name,
      nodes: nodes,
      node_pids: node_pids,
      events: [],
      render_interval: render_interval,
      speed: speed,
      running_since: System.monotonic_time(:millisecond)
    }

    Process.send_after(self(), :render, 0)
    {:ok, state}
  end

  def handle_info(:render, state) do
    book = TradingEngine.book(state.engine_name)
    history = TradingEngine.history(state.engine_name)
    rendered = render_dashboard(state, book, history)
    IO.write(rendered)
    Process.send_after(self(), :render, state.render_interval)
    {:noreply, state}
  end

  def handle_info({:node_order, node_id, order, book}, state) do
    {nodes, event} = update_nodes(state.nodes, node_id, order, book)

    {:noreply,
     %{state | nodes: nodes, events: [event | state.events] |> Enum.take(@max_events)}}
  end

  def handle_info({:EXIT, _pid, _reason}, state), do: {:noreply, state}

  defp node_loop(node, dashboard_pid, engine_name, speed) do
    :rand.seed(:exsplus, random_seed(node.id))
    loop(node, dashboard_pid, engine_name, speed)
  end

  defp loop(node, dashboard_pid, engine_name, speed) do
    Process.sleep(random_delay(speed))

    order = random_order(node)
    {:ok, book} = TradingEngine.submit_order(engine_name, order)
    send(dashboard_pid, {:node_order, node.id, order, book})

    loop(node, dashboard_pid, engine_name, speed)
  end

  defp random_order(node) do
    side = if :rand.uniform() > 0.5, do: :buy, else: :sell
    price = random_price(side)
    quantity = :rand.uniform(16)

    Order.new("#{node.id}-#{System.unique_integer([:positive])}", price, quantity, side)
  end

  defp random_price(:buy) do
    price = 98.0 + :rand.uniform() * 8.5
    :erlang.float_to_binary(price, decimals: 2)
  end

  defp random_price(:sell) do
    price = 96.5 + :rand.uniform() * 8.5
    :erlang.float_to_binary(price, decimals: 2)
  end

  defp random_delay(speed) do
    base = trunc(850 / max(speed, 0.4))
    max(140, base + :rand.uniform(250))
  end

  defp random_seed(id) do
    base = :erlang.phash2({id, node(), self(), System.system_time()})
    {base, base + 1_001, base + 2_003}
  end

  defp build_nodes(count) do
    names = ["Atlas", "Kite", "Orion", "Pulse", "Delta", "Nova", "Vector"]

    Enum.map(1..count, fn index ->
      %{
        id: "node-#{index}",
        name: Enum.at(names, rem(index - 1, length(names))),
        sent: 0,
        matched_volume: 0,
        last_side: :buy,
        last_price: "--",
        last_qty: 0,
        last_state: :idle
      }
    end)
  end

  defp update_nodes(nodes, node_id, order, book) do
    {updated_nodes, updated_node} =
      Enum.map_reduce(nodes, nil, fn node, acc ->
        if node.id == node_id do
          matched = matched_volume(order, book)

          updated = %{
            node
            | sent: node.sent + 1,
              matched_volume: node.matched_volume + matched,
              last_side: order.side,
              last_price: Decimal.to_string(order.price),
              last_qty: order.quantity,
              last_state: if(matched > 0, do: :matched, else: :queued)
          }

          {updated, updated}
        else
          {node, acc}
        end
      end)

    event = %{
      node: updated_node.name,
      side: order.side,
      qty: order.quantity,
      price: Decimal.to_string(order.price),
      matched: matched_volume(order, book),
      time: time_string()
    }

    {updated_nodes, event}
  end

  defp matched_volume(order, book) do
    side = if order.side == :buy, do: :buy_orders, else: :sell_orders

    residual =
      book
      |> Map.get(side, [])
      |> Enum.find(fn item -> item.id == order.id end)

    residual_quantity = if residual, do: residual.quantity, else: 0
    order.quantity - residual_quantity
  end

  defp render_dashboard(state, book, history) do
    {best_bid, best_ask} = best_prices(book)
    open_volume = open_volume(book)
    total_submitted = Enum.reduce(history, 0, fn order, acc -> acc + order.quantity end)
    filled_volume = total_submitted - open_volume
    spread = spread(best_bid, best_ask)
    spread_label = spread_label(spread)
    elapsed = System.monotonic_time(:millisecond) - state.running_since

    [
      IO.ANSI.home(),
      IO.ANSI.clear(),
      IO.ANSI.bright(),
      IO.ANSI.cyan(),
      "Trading Engine - demo em Elixir\n",
      IO.ANSI.reset(),
      "Tempo ativo: ", Integer.to_string(div(elapsed, 1000)), "s",
      "  |  Ordens: ", Integer.to_string(length(history)),
      "  |  Volume preenchido: ", Integer.to_string(filled_volume),
      "  |  Spread: ", spread_label, "\n\n",
      render_columns(state, book),
      "\n",
      render_levels("BUY BOOK", book.buy_orders, :desc),
      "\n",
      render_levels("SELL BOOK", book.sell_orders, :asc),
      "\n",
      render_events(state.events)
    ]
  end

  defp render_columns(state, book) do
    top_node_lines =
      state.nodes
      |> Enum.map(fn node ->
        side = node.last_side |> Atom.to_string() |> String.upcase()

        [
          IO.ANSI.green(),
          String.pad_trailing(node.name, 8),
          IO.ANSI.reset(),
          " | ordens: ", String.pad_leading(Integer.to_string(node.sent), 3),
          " | match: ", String.pad_leading(Integer.to_string(node.matched_volume), 3),
          " | ultima: ", side,
          " ", String.pad_leading(Integer.to_string(node.last_qty), 2),
          " @ ", String.pad_leading(node.last_price, 7),
          " | ", status_label(node.last_state)
        ]
      end)
      |> Enum.intersperse("\n")

    best_bid = book.buy_orders |> List.first() |> render_best(:buy)
    best_ask = book.sell_orders |> List.first() |> render_best(:sell)

    [
      IO.ANSI.bright(), "Nodos", IO.ANSI.reset(), "\n",
      top_node_lines, "\n\n",
      "Melhor bid: ", best_bid, "\n",
      "Melhor ask: ", best_ask, "\n"
    ]
  end

  defp render_best(nil, _side), do: "--"
  defp render_best(order, _side), do: "#{Decimal.to_string(order.price)} x #{order.quantity}"

  defp render_levels(title, orders, _direction) do
    levels = orders |> Enum.take(@max_levels) |> Enum.map(&render_level/1)

    [
      IO.ANSI.bright(), title, IO.ANSI.reset(), "\n",
      case levels do
        [] -> "  (vazio)\n"
        _ -> Enum.map_join(levels, "\n", &(&1)) <> "\n"
      end
    ]
  end

  defp render_level(order) do
    ["  ", String.pad_trailing(order.id, 14), "  ", format_price(order.price), "  x  ", Integer.to_string(order.quantity)]
    |> IO.iodata_to_binary()
  end

  defp render_events(events) do
    header = [IO.ANSI.bright(), "Eventos recentes", IO.ANSI.reset(), "\n"]

    body =
      events
      |> Enum.take(@max_events)
      |> Enum.map(fn event ->
        side = if event.side == :buy, do: IO.ANSI.green(), else: IO.ANSI.red()

        [
          "  ", event.time, "  ", side, String.upcase(Atom.to_string(event.side)), IO.ANSI.reset(),
          "  ", event.node, "  ", event.qty, " @ ", event.price,
          "  | matched: ", Integer.to_string(event.matched)
        ]
      end)
      |> Enum.intersperse("\n")

    [header, body, if(events == [], do: "  (aguardando eventos)\n", else: "\n")]
  end

  defp best_prices(book), do: {book.buy_orders |> List.first(), book.sell_orders |> List.first()}

  defp open_volume(book) do
    Enum.reduce(book.buy_orders, 0, fn order, acc -> acc + order.quantity end) +
      Enum.reduce(book.sell_orders, 0, fn order, acc -> acc + order.quantity end)
  end

  defp spread(nil, _), do: 0.0
  defp spread(_, nil), do: 0.0

  defp spread(best_bid, best_ask) do
    Decimal.sub(best_ask.price, best_bid.price)
    |> Decimal.to_float()
  end

  defp spread_label(value) when value < 0 do
    ["cruzado (", format_price(value), ")"] |> IO.iodata_to_binary()
  end

  defp spread_label(value), do: format_price(value)

  defp format_price(price) when is_binary(price), do: price
  defp format_price(price) when is_float(price), do: :erlang.float_to_binary(price, decimals: 2)
  defp format_price(price), do: Decimal.to_string(price)

  defp time_string do
    {{_year, _month, _day}, {hour, minute, second}} = :calendar.local_time()
    [pad(hour), ":", pad(minute), ":", pad(second)] |> IO.iodata_to_binary()
  end

  defp normalize_engine_name(name) when is_atom(name), do: name
  defp normalize_engine_name(name) when is_binary(name), do: String.to_atom(name)

  defp pad(number), do: number |> Integer.to_string() |> String.pad_leading(2, "0")

  defp status_label(:matched), do: [IO.ANSI.green(), "matched", IO.ANSI.reset()]
  defp status_label(:queued), do: [IO.ANSI.yellow(), "queued", IO.ANSI.reset()]
  defp status_label(:idle), do: [IO.ANSI.light_black(), "idle", IO.ANSI.reset()]

  defp render_interval(speed), do: max(120, trunc(1000 / max(speed, 0.4)))
end