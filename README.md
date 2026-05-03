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

Estado atual da suite:

- O teste existente falha porque `TradingEngine.hello/0` nao esta implementada.
- O `OrderBook` tambem emite warnings de comportamento incompleto, porque a interface GenServer ainda nao foi fechada.

Validacao pratica recomendada enquanto o fluxo publico nao existe:

- Criar ordens em IEx com `Order.new/4`.
- Testar o matching manualmente chamando `Matcher.match_order/2`.
- Verificar se a ordenacao esperada do livro continua consistente quando novas ordens sao inseridas.

## O que falta fazer

### Para o projeto ficar utilizavel

- Expor uma API publica em `TradingEngine` para receber, validar e processar ordens.
- Conectar `OrderBook` ao fluxo real de insercao, remocao e consulta de ordens.
- Definir claramente as operacoes permitidas: criar ordem, cancelar ordem, consultar livro e consultar historico.
- Tratar casos de erro e validacao de entrada, como side invalido, quantidade negativa e preco ausente.
- Ajustar os tipos e retornos do matcher para cobrir match parcial, match total e sobra de quantidade.

### Para distribuir com seguranca

- Completar metadados do pacote em `mix.exs`.
- Adicionar descricao do pacote, links do projeto, licenca e arquivos de publicacao.
- Revisar versao e estrategia de release antes de publicar no Hex.
- Escrever documentacao da API publica com exemplos reproduziveis.

### Para testar melhor

- Corrigir ou substituir o teste atual que chama `TradingEngine.hello/0`.
- Cobrir `Order.new/4` com testes de conversao de preco e timestamp.
- Cobrir os cenarios de matching parcial, total e sem cruzamento.
- Adicionar testes do livro de ordens para ordem de ordenacao e atualizacao de estado.
- Criar testes de integracao para o fluxo completo de entrada de ordem ate o update do livro.

## Instalacao

Se o pacote for publicado no Hex, ele pode ser usado adicionando a dependencia abaixo ao `mix.exs` de outro projeto:

```elixir
def deps do
  [
    {:trading_engine, "~> 0.1.0"}
  ]
end
```

## Proximos passos sugeridos

1. Definir a API publica do motor de trading.
2. Escrever testes de matching e de livro de ordens.
3. Corrigir a base de publicacao no Hex e documentar o fluxo de uso.

