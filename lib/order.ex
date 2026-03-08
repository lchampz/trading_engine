defmodule Order do
    @enforce_keys [:id, :price, :quantity, :side]
    defstruct [:id, :price, :quantity, :side, :timestamp]

    def new(id, price, quantity, side) do
      %__MODULE__{
        id: id,
        price: Decimal.new(price),
        quantity: quantity,
        side: side,
        timestamp: DateTime.utc_now()
      }
    end
end
