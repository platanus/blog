---
layout: post
title: Listas desde Cero
subtitle: Una poco común introducción a la programación funcional
author: juliogarciag
excerpt: Una poco común introducción a la programación funcional reimplementando las colecciones de ruby desde 0
tags:
  - ruby
  - functional-programming
---

Imaginemos un ruby extraño:

- Sin estructuras de datos como arrays o hashes.
- Sin loops nativos como `for`, `while` o `loop`.
- Sin clases: sólo funciones.

La idea de este post es una prueba de concepto. La idea es explicar algunos conceptos de la programación funcional que no se ven tanto en la vida diaria pero que ayudan mucho a pensar en ese sentido. Imaginémonos en una situación tan limitada que debemos reconstruir — desde 0 — las cosas que siempre damos por sentadas en ruby únicamente con funciones.

## Iteraciones

Comencemos por una simple iteración. Tenemos que conseguir la suma de números en el rango de `x` a `y`. Siempre hemos usado bucles (`while`, `loop`) o métodos del módulo enumerable (`each`, `map`, `reduce`) para ejecutar algo repetidas veces. Por ejemplo, si tuviésemos que implementar esto:

```ruby
def sum_numbers(x, y)
end

sum_numbers(1, 10) # Expected: 55
```

Usaríamos posiblemente un `each` que itera sobre un rango acumulando una suma en una variable o algo similar. ¿Cómo lo haríamos sin estas herramientas que siempre usamos? (En serio, piensa un momento sobre esto sin continuar)

Si no has hallado ya la respuesta — o sí pero quieres seguir leyendo —, recordemos por un momento la primera vez que aprendimos sobre funciones recursivas. Posiblemente hayan hecho una versión de la función de factorial hecha recursivamente (si no, pueden hechar un vistazo [aquí](http://natashatherobot.com/recursion-factorials-fibonacci-ruby/) o [aquí](https://gist.github.com/fmeyer/289467#file-evolution-of-a-python-programmer-py-L1) muy similar a ésta:

```ruby
def factorial(n)
  if n == 1 || n == 0
    1
  else
    n * factorial(n - 1)
  end
end

factorial(3) # 6
```

Si bien es muy expresiva y útil para enseñar lo que es una función recursiva, hay que tener en cuenta — muy en cuenta — que esta misma función puede implementarse con una simple iteración así:

```ruby
def factorial(n)
  factorial = 1
  while n > 1
    factorial = factorial * n
    n = n -1
  end
  factorial
end
```

Por ende, es importante reconocer que ambas formas son en realidad lo mismo: Estamos volviendo a ejecutar código que ya ejecutamos, en contextos distintos (con argumentos distintos). La gran diferencia es que la forma recursiva es quizás menos natural para nosotros y no requiere de construcciones adicionales en el lenguaje (como `while` o `loop`). La siguiente es la función `sum_numbers` que necesitábamos antes pero implementada de forma recursiva:

```ruby
def sum_numbers(number, final, total = 0)
  if number > final
    total
  else
    sum_numbers(number + 1, final, total + number)
  end
end

sum_numbers(1, 10)
```

La regla de oro con las funciones recursivas es encontrar la condición de salida (la primera línea de la función). Sin una condición de salida, fracasaremos en salir de la función (ingresaríamos en un bucle infinito). La idea es usar a la misma función como la continuación de lo que estamos computando y sólo salir cuando ya estamos listos. En este caso usamos el primer y tercer parámetros de la función (`number` y `total`) para representar el estado de lo que estamos haciendo, y el segundo parámetro para poder siempre preguntar por la condición de salida. Si tuviésemos logs de los parámetros en cada llamada (lo que podemos hacer con un `puts` en el principio de la función), tendríamos esto:

```
number: 1, final: 10, total: 0
number: 2, final: 10, total: 1
number: 3, final: 10, total: 3
number: 4, final: 10, total: 6
number: 5, final: 10, total: 10
number: 6, final: 10, total: 15
number: 7, final: 10, total: 21
number: 8, final: 10, total: 28
number: 9, final: 10, total: 36
number: 10, final: 10, total: 45
number: 11, final: 10, total: 55
```

Como ves, hemos usado el tercer parámetro (valiéndonos de los parámetros por defecto de ruby para no tener que colocar el 0) para acumular el resultado (`total + number`) hasta alcanzar la condición de salida (`number > total`). El incremento del primer parámetro (`total + 1`) determina el avance de la función. Una nota curiosa de este modo de hacer loops es que, en cada iteración, el estado del programa es copiado y pasado a la siguiente llamada en lugar de transformarse. No hay una variable transformada en cada iteración, sino que la recursión nos permite tener un código perfectamente [inmutable](https://en.wikipedia.org/wiki/Immutable_object).

## Listas Enlazadas

Bueno, ahora que tenemos un loop y sabemos que toda iteración puede representarse con funciones recursivas, pensemos en cómo representar una lista. Primero, es importante mencionar que no estamos implementando un array sino una [lista enlazada](https://es.wikipedia.org/wiki/Lista_(informática)). Segundo, la razón es porque una lista enlazada nos hace pensar en la naturaleza de todo tipo de colecciones y el objetivo que tienen: crear un lazo entre uno o más objetos (números, strings, etc) entre sí. Podríamos, dado que estamos usando ruby, usar clases y atributos para crear esos lazos pero — *for the sake of experiment* — vamos a pensar en algo a más bajo nivel. Si tuviésemos una función así:

```ruby
def cons(x, y)
end
```

¿Cómo haríamos para seleccionar x o y? Probemos usando una lambda.

```ruby
def cons(x, y = nil)
  lambda do |selector|
    selector == :left ? x : y
  end
end

node = cons(1, 2)
node.call(:left) # 1
node.call(:right) # 2
```

Puede parecer rarísimo a primera vista (hey, estamos usando una lambda y un `if` para simular la asociación de dos valores en vez de usar una clase como haríamos en la vida real!) pero es una demostración del principio por el cual *todo* puede representarse sólo usando lambdas. (Vean un Fizz Buzz [aquí](http://codon.com/programming-with-nothing#victory) para un ejemplo) En nuestro experimento ahora vamos a crear dos funciones que nos ayuden a seleccionar un valor sin tener que hacer `node.call(:left)` o `node.call(:right)` directamente. Les llamaremos `head` y `rest`.

```ruby
def head(node)
  node.call(:left)
end

def rest(node)
  node.call(:right)
end
```

Podemos componer nodos con otros nodos sólo creando referencias entre sí:

```ruby
cons(1, cons(2, cons(3, cons(4))))
# Que es lo mismo que:
cons(1, cons(2, cons(3, cons(4, nil))))
# sólo que estamos usando parámetros por defecto para evitar ponerlo siempre.
```

Usamos `nil` como la referencia final del nodo (`nil` significa nada). En teoría podemos utilizar cualquier valor que sea único (cualquier singleton del lenguaje) pero usar `nil` tiene más sentido en tanto ya es un singleton embebido en ruby y existe un método para preguntar por él: `nil?`. Sin embargo, es poco expresivo que usemos `nil?` para expresar que algo no tiene nodos (o sea, que está vacío), así que crearemos una función `empty?`:

```ruby
def empty?(node)
  node.nil?
end
```

El hecho de que podamos componer una lista de nodos enlazados sólo por el tipo de parámetros que recibe una lambda puede parece poco nomal pero es sumamente poderosa. ¿Cómo así? Imaginemos que queremos saber cuántos elementos tiene esa lista. Podemos crear una función `length` con esto:

```ruby
def length(node, current_length = 0)
  if empty?(node)
    current_length
  else
    length(rest(node), current_length + 1)
  end
end

length(nil) # 0
length(cons("a")) # 1
length(cons("a", cons("b"))) # 2
length(cons("a", cons("b", cons("c"))))
```

En esta implementación de `length` hemos usado uno de los parámetros (`current_length`) para acumular el tamaño de la lista (iniciándolo con 0 gracias a los parámetros por defecto y usando `current_length + 1` para aumentarlo) y hemos iterado recursivamente hasta encontrarnos con un nodo vacío. Esta simple implementación de `length` es básicamente cómo pensar:

- El tamaño de una lista vacía es 0. (el valor por defecto)
- El tamaño de una lista es 1 más el tamaño del resto de la lista.

La idea con la lista enlazada es que es una colección muy simple de implementar y no requiere manejo alguno de memoria (como los arrays). Hasta ahora te he dicho que es una colección ¡pero hasta ahora sólo he implementado dos métodos demasiado simples! Implementemos algo que toda colección debe tener entonces: la función `each`.

## Each

Pensemos de la misma forma que el otro algoritmo:
- `each` en una lista vacía no hace nada.
- `each` en una lista de un sólo elemento ejecuta el bloque con la cabeza de la lista.
- `each` en una lista cualquiera ejecuta el bloque con la cabeza de la lista y luego hace lo mismo con el resto de la lista.

```ruby
def each(node, &iterator)
  if !empty?(node)
    iterator.call(head(node))
    each(rest(node), &iterator)
  end
end
```

Wow, eso fue hasta más corto que hacerlo de forma iterativa (en realidad no pero estuvo cerca). La idea es llamar al iterador por cada vez que se llame a `each` y luego vamos llamando a la misma función con el resto de lista hasta que el resto no sea nada. Eso es todo. Es el mismo patrón que antes: Iteramos hasta que la lista esté vacía y hacemos una computación al respecto.

Sólo como un pequeño dato de trivia: `head` y `rest`, son los equivalentes a los que en las primeras implementaciones de [Lisp](https://es.wikipedia.org/wiki/Lisp) fueron llamados `car` y `cdr`. No estoy usando aquí esos nombres porque responden a razones históricas, pero es interesante saber que son las mismas funciones.

# Map y Filter

Lo siguiente a implementar es `map`. Sí, esa función que itera sobre una lista y foma otra lista con valores equivalentes a cada valor de la lista original tras haber pasado por una función que es pasada como argumento. Si esa explicación fue poco esclarecedora o no recordaste qué era map, este ejemplo del `map` nativo de ruby debería ayudar:

```ruby
[1, 2, 3].map { |x| x * x } == [1, 4, 9]
```

Bueno, ahora que lo entendemos, implementemos `map` (lo explicaré luego de implementarlo esta vez):

```ruby
def map(node, &block)
  if empty?(node)
    nil # el `map` de una lista vacía es siempre una lista vacía
  else
    cons(
      block.call(head(node)),
      map(rest(node), &block)
    )
  end
end

xs = cons(:a, cons(:b, cons(:c)))
head(map(xs) { |x| x.to_s.capitalize }) # A
```

Aquí la lógica es simple: para hacer una segunda lista, tenemos que usar `cons` pero usando `block.call(head(node))` en vez de usar `head(node)` directamente. Luego de ello, volvemos a formar el nodo recursivamente llamando otra vez a `map`. Más o menos así:

1. `map` con `[1, 2, 3]` es equivalente a `cons(block.call(1), map([2, 3], &block))`.
2. Para calcular `map` con `[2, 3]`, hacemos `cons(block.call(2), map([3], &block))`
2. Para calcular `map` con `[3]`, hacemos `cons(block.call(3), map(nil, &block))`
3. Finalmente, al calcular `map` con `nil` tenemos `nil`.

Así que en realidad tenemos:

```ruby
cons(block.call(1), cons(block.call(2), cons(block.call(3), nil)))
```

Esto significa que hemos, recursivamente, llamado a `block.call` con cada elemento de la lista y los hemos juntado en una sola.

Ahora, para implementar `filter`, pondré un ejemplo del clásico uso del filter nativo de ruby (llamado `select` o `find_all`):

```ruby
[1, 2, 3].select { |x| x.even? } == [2]
```

Y lo implementaremos ahora:

Sabiendo cómo hacer `map`, ¿cómo haríamos `filter`? Tendríamos que acumular en una lista los miembros de una lista inicial sólo si el predicado es verdadero y deberíamos continuar con el resto de la si no lo es. Para el caso de usar un predicado si revise que un valor es par (`x.even?`), necesitamos ir achicando nuestra lista a la vez que acumulamos los valores que pasaron el predicado:

1. Primero tendremos `[1, 2, 3]` y una lista con la acumulación actual `[]`: Cogemos `1` y ejecutamos el predicado. Como no es verdadero, seguimos con el siguiente: `[2, 3]`
2. Ahora tenemos `[2, 3]` y la acumulación `[]`: Cogemos 2 y ejecutamos el predicado. Como es verdadero, pasamos el acumulado más el valor que acabamos de probar: `[2]` además del resto de la lista: `[3]`.
3. Ahora tenemos `[3]` y la acumulación `[2]`: Cogemos 3 y ejecutamos el predicado con él, lo que resulta ser falso, así que sólo seguimos con el siguiente: `nil`.
4. Aquí tenemos que terminar el asunto. Si la lista es vacía (`nil`), entonces retornamos lo que hemos venido acumulando: `[2]`.

Si este plan está bien, debería bastarnos con esta implementación:

```ruby
def filter(node, filtered = nil, &block)
  if empty?(node)
    filtered
  else
    value = head(node)
    rest = rest(node)
    if block.call(value)
      filter(rest, cons(value, filtered), &block)
    else
      filter(rest, filtered, &block)
    end
  end
end

list = cons(1, cons(2, cons(3)))
length(filter(list) { |x| x.odd? }) # 2
```

Para `concatenar` en realidad estamos creando otro nodo con el valor que hemos obtenido más lo demás que está filtrado (`cons(value, filtered)`). De este modo pasamos el total filtrado hasta que agotamos la lista y tenemos que devolver lo filtrado. Bueno, ahora que tenemos `filter`, terminemos esta reimplementación con `reduce`, también llamada `fold` e `inject`. (dependiendo del lenguaje)

## Fin: Reduce y otra vez Map y Filter

`reduce` consiste en reducir un valor mientras se itera en una colección para obtener otro valor. Por ejemplo, para conseguir la suma de todos los valores de una lista podemos hacer (usando el `reduce` de ruby):

```ruby
[1, 2, 3, 4, 5].reduce(0) { |total, x| total + x } == 15
```

Para implementar nuestro `reduce` con nuestras — *hand-made* — estructuras necesitaríamos una implementación similar a `filter` pero "transformando" el acumulador de otro modo:

```ruby
def reduce(node, accumulated, &block)
  if empty?(node)
    accumulated
  else
    new_accumulator = block.call(accumulated, head(node))
    reduce(rest(node), new_accumulator, &block)
  end
end

list = cons(1, cons(2, cons(3, cons(4, cons(5)))))
puts reduce(list, 0) { |t, x| t + x }
```

Aquí la implementación es sumamente similar (pero más simple) que la de `filter`. La única diferencia es que en vez del `if/else` tenemos una sola acción que calcula un nuevo acumulador en cada iteración. Como el anterior acumulador desaparece, es como si transformáramos el acumulador en cada iteración. Sin embargo, puesto que pasamos un nuevo valor, no estamos realmente mutando ese valor: es, en términos prácticos, inmutable.

Ahora que tenemos un `reduce`, pensemos un poco en qué es lo que `reduce` hace. No es normal que nos detengamos a pensar en esto pero, para el caso de este post, es importante: `reduce` transforma un valor mediante una computación a través de una lista. Eso es todo. Es demasiado general en realidad. La verdad es que `reduce` es tan general que podríamos implementar `map` y `filter` usando `reduce` en vez de las implementaciones que teníamos. Comencemos por `map`:

```ruby
def map_2(node, &block)
  reduce(node, nil) do |mapped, x|
    cons(block.call(x), mapped)
  end
end

list = cons(1, cons(2, cons(3, cons(4, cons(5)))))
head(map_2(list) { |x| x * x }) # 25
```

¡Listo! Usando `reduce` tenemos una implementación de `map` mucho más simple y natural: Construímos una lista usando `block.call` en cada elemento de la lista inicial.

Pero hay un problema: ¡La lista ha sido formada al revés! Como `reduce` va de izquierda a derecha colocando los valores al comienzo de la lista y `cons` construye listas colocando valores a la izquierda, todo está al revés. Las listas enlazadas son muy útiles si quieres agregar un objeto al comienzo porque es sumamente simple, pero si quieres hacer lo contrario (pushear un valor al final) tienes que hacer algo más complejo.

Crearemos, entonces, la función `append(node, value)`. ¿Cómo lo haríamos? La idea es ir formando una lista con los mismos `head` de la lista inicial hasta que llegamos a un valor vacío. En este caso, en vez de devolver el nodo (`nil`) devolvemos el valor que queremos juntar (`value`) envuelto en un nodo. Es como si básicamente reemplazáramos el final de la lista `nil` con `cons(node, nil)`:


```ruby
def append(node, value)
  if empty?(node)
    cons(value, nil)
  else
    cons(head(node), append(rest(node), value))
  end
end

list = cons(1, cons(2, cons(3, cons(4, cons(5)))))
head(rest(rest(rest(rest(rest(append(list, 6))))))) # 6 (ok, esto ya es muyyy largo)
```

Ahora, el problema con un `append` es que es más costoso que sólo crear una lista con `cons` y agregar el elemento detrás. `cons` es tan simple que la cantidad de cosas a hacer es siempre la misma así tengamos millones de datos (a esto se le llama complejidad constante) mientras que `append` requiere hacer operaciones equivalentes a cuántos elementos hay porque debemos navegar hasta el final. Por ende, las listas enlazadas no son buenas para agregar data al final de una colección pero vencen a cualquier otra estructura de datos en agregar un elemento al principio.

Bueno, ahora que tenemos `append`, reimplementemos nuestro `map_2`:

```ruby
def map_2(node, &block)
  reduce(node, nil) do |mapped, x|
    append(mapped, block.call(x))
  end
end

list = cons(1, cons(2, cons(3, cons(4, cons(5)))))
head(rest(map_2(list) { |x| x * x })) # 4
```

Y listo: funcionó en orden y quizás ahora sea un poco más simple de leer (`append` suena mejor que `cons`).

Ahora hagamos `filter`:

```ruby
def filter_2(node, &block)
  reduce(node, nil) do |filtered, x|
    if block.call(x)
      append(filtered, x)
    else
      filtered
    end
  end
end

list = cons(1, cons(2, cons(3, cons(4, cons(5)))))
puts head(filter_2(list) { |x| x.even? })
```

Como verán, `filter` es sólo un `reduce` que acumula una lista filtrada la cual es modificada si es que el predicado es correcto y no lo hace cuando no lo es. Dado que ya hemos implementado `append`, la lista está ordenada correctamente.

## Conclusión

Bien, esto puede haber parecido muy raro y quizás — sólo quizás — poco útil si lo quisiéramos aplicar directamente a la vida real, pero es interesante poder crear las cosas que asumimos existen en el lenguaje desde 0. Es como estar más cerca del algoritmo mismo y nos obliga a buscar soluciones curiosas y a pensar de dos formas que normalmente no usamos en la programación procedural: recursiva e inmutablemente. Solemos, en la programación procedural del día a día, mutar datos de muchas maneras y preocuparnos poco porque nuestras funciones no provoquen efectos colaterales en otras partes del sistema, así que esto podría ayudar. Más allá de eso, encuentro divertido el hecho poder hacer tantas cosas con tan poco.
