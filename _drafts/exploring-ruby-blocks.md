---
layout: post
title: Explorando los bloques de Ruby
author: arturopuente
tags:
  - ruby
  - blocks
  - code
  - rails
---

Uno de los puntos más fuertes de Ruby son sus bloques: elegantes y potentes, nos permiten crear código legible y expresivo. La influencia de estos bloques se ha expandido a otros lenguajes, y estos a su vez han iterado sobre el concepto y aportado algunas características interesantes.

Veamos, por ejemplo, la dosis de azúcar sintáctico conocida como *placeholders* en Scala (nótese el uso de `_` en reemplazo de la variable `a` en el segundo bloque):

```javascript
List(1, 2, 3).foreach(a => print(a))
List(1, 2, 3).foreach(print(_))
```

Me nació la duda sobre si era posible implementar esto en Ruby, terminé llegando a algo que se ve de esta forma:

```ruby
anon { puts _ }.call([1, 2, 3])
```

```ruby
# Empezamos por la definición del método anon, que recibe un bloque
def anon(&block)
end

anon { }.call([])

# Pero también podría ser llamado de esta forma, por lo
# que necesitamos recibir ese bloque que se envía como argumento

fn = ->{ }
anon(fn).call([])

# Modificamos un poco la definición para darle soporte a ambas llamadas

def anon(block_from_args = nil, &block)
  block ||= block_from_args
end
```

## Identificando bloques anónimos

Ahora bien, para manejar los bloques anónimos primero debemos verificar si el bloque tiene o no parámetros, esto lo podemos hacer gracias a `Proc#arity`, según estos valores:

```ruby
Proc.new { }.arity            #=>  0
Proc.new { || }.arity         #=>  0
Proc.new { |a| }.arity        #=>  1
Proc.new { |a, b| }.arity     #=>  2
Proc.new { |a, b, c| }.arity  #=>  3
Proc.new { |*a| }.arity       #=> -1
Proc.new { |a, *b| }.arity    #=> -2
Proc.new { |a, *b, c| }.arity #=> -3
```

Con esto podemos determinar si el bloque recibe o no parámetros:

```ruby
def anon(block_from_args = nil, &block)
  block ||= block_from_args
  arity = block.arity
  # Esto devolverá el bloque sin modificaciones en caso de
  # que declare algún parámetro
  return block if arity < 0

  # De lo contrario, aquí manejamos el .call posterior al bloque
  -> (*args) do
    # Esto falla porque aún no hemos definido el método _
    block.call
  end
end
```

## Definiendo el valor de _

```ruby
def define_underscore_arguments(args)
  # Aquí definimos _, que es un proc que devuelve el primer argumento
  Object.__send__(:define_method, :_, ->{ args[0] })
  # Esta función la usaremos después de ejecutar la llamada
  # para dejar limpio el namespace global
  ->{ Object.__send__(:remove_method, :_) }
end

def anon(block_from_args = nil, &block)
  block ||= block_from_args
  arity = block.arity
  return block if arity < 0

  -> (*args) do
    # Definimos _ y guardamos una función que remueve _
    cleanup = define_underscore_arguments(args)
    block.call
    # Removemos _
    cleanup.call
  end
end
```

El último paso es asegurarnos de que aún si ocurre una excepción, el namespace global se mantendrá limpio, por esto incluiremos las llamadas dentro de un bloque begin/ensure:

```ruby
def anon(block_from_args = nil, &block)
  block ||= block_from_args
  arity = block.arity
  return block if arity < 0

  -> (*args) do
    cleanup = define_underscore_arguments(args)
    # Ambas llamadas van dentro de un begin/ensure
    # ensure es como un finally en un try/catch
    begin
      block.call
    ensure
      cleanup.call
    end
  end
end

anon { puts _.reverse.to_s }.call([1, 2, 3, 4, 5]) #=> [5, 4, 3, 2, 1]
puts Object.method_defined?(:_)                    #=> false
```
