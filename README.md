# TradingEngine

TradingEngine e uma base de motor de matching para ordens de compra e venda em Elixir.
O projeto hoje concentra tres pecas principais:

- [Order](lib/order.ex), que representa uma ordem com `id`, `price`, `quantity`, `side` e `timestamp`.
- [Matcher](lib/matcher.ex), que contem a logica de confronto entre uma ordem de entrada e uma fila de ordens opostas.
- [OrderBook](lib/order_book.ex), que guarda os lados de compra e venda e o historico do livro.

Na pratica, isso significa que o repositório ainda esta na fase de nucleo tecnico: ha a estrutura do dominio e parte da logica de matching, mas ainda falta integrar tudo em um fluxo publico de uso, persistencia e distribuicao.

## Estado atual

O codigo existente ja aponta para estes comportamentos:

- Criacao de ordens com preco em `Decimal`.
- Ordenacao das ordens por preco para ambos os lados do livro.
- Regras basicas de matching quando ha compatibilidade entre compra e venda.
- Inicializacao de um processo GenServer para a aplicacao principal.
Ao mesmo tempo, o projeto ainda esta incompleto. Hoje ha, por exemplo, teste quebrando por falta de `TradingEngine.hello/0`, e o `OrderBook` ainda tem funcoes internas nao conectadas ao fluxo publico.

## Como usar localmente

Para compilar o projeto:

```bash
mix deps.get
mix compile
```

Para iniciar o IEx com o projeto carregado:

```bash
iex -S mix
```

Exemplos do que ja existe hoje no codigo:

```elixir
buy = Order.new("1", "100.50", 10, :buy)
sell = Order.new("2", "99.00", 10, :sell)

Matcher.match_order(buy, [sell])
```

## Como testar na pratica

Teste automatizado:

```bash
mix test
```

## Demo visual no terminal

Existe uma demo nativa em Elixir que sobe varios nodes concorrentes, gera ordens aleatorias e desenha o book real da engine no terminal em tempo real.

Para abrir, rode:

```bash
mix demo
```

Voce tambem pode ajustar o numero de nodes e a velocidade:

```bash
mix demo --nodes 7 --speed 1.4
```