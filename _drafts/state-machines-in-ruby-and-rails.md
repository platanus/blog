---
layout: post
title: Máquinas de Estado en Ruby y en Ruby on Rails

---

Quizás hayan oído hablar de las [máquinas de estado](http://en.wikipedia.org/w/index.php?title=Finite-state_machine&redirect=no) antes y quizás no parezca una de esas cosas que siempre se usan o sea medio extraño hallarle un caso de uso a simple vista. Para los que no hayan oído hablar de ellas, una máquina de estados es una abstracción sobre el proceso mediante el cual un objeto pasa de un estado a otro. Pero, ¿No basta con cambiar el estado de algo y fin? Podría ser, pero sería más desordenado y menos expresivo. Para dejar en claro cómo es que usar una máquina de estados es útil, vamos a implementar un objeto mediante una máquina de estados: un torniquete, como los que vemos en supermercados, bancos, metros, etc. Uno así:

![][1]

Como realmente la gema que vamos a usar para implementar una máquina de estados no es específica de Rails, primero probaremos con un simple script de ruby luego de haber instalado la gema. Hay varias gemas para máquinas de estados pero me parece que la más estable y soportada es [AASM](https://github.com/aasm/aasm), que quiere decir algo como **Act as State Machine**.

Instalar la gema es tan simple como `gem install aasm` y crear un simple script para jugar es tan simple como `touch state-machine-example.rb`. 

Teniendo esto, pensemos primero en que un torniquete (`Turstile`) es algo que recibe dos actos: La inserción de una moneda y el empuje de una persona. El torniquete está en un principio bloqueado. Al insertar una moneda, la máquina se desbloquea y podemos realizar un empuje y pasar. Una vez el empuje ha terminado, la máquina se bloquea de nuevo. Podríamos implementar el funcionamiento del torniquete así:

```ruby
class Turnstile
  attr_reader :state

  STATE_LOCKED = :locked
  STATE_UNLOCKED = :unlocked

  def initialize
    self.state = STATE_LOCKED
  end

  def insert_coin
    if self.state != STATE_UNLOCKED
      puts "insert: SE COLOCA UNA MONEDA"
      self.state = STATE_UNLOCKED
    else
      puts "insert: SE COLOCA LA MONEDA PERO NADA PASA"
    end
  end

  def push_handle
    if self.state == STATE_UNLOCKED
      puts "push: DESBLOQUEANDO EL CAMINO"
      self.state = STATE_LOCKED
    else
      puts "push: SE EMPUJO LA MAQUINA PERO ESTA BLOQUEADA"
    end
  end

  private

  attr_writer :state
end

turnstile = Turnstile.new
turnstile.insert_coin # insert: SE COLOCA UNA MONEDA
turnstile.push_handle # push: DESBLOQUEANDO EL CAMINO
turnstile.push_handle # push: SE EMPUJO LA MAQUINA PERO ESTA BLOQUEADA
turnstile.insert_coin # insert: SE COLOCA UNA MONEDA
turnstile.push_handle # push: DESBLOQUEANDO EL CAMINO
turnstile.push_handle # push: SE EMPUJO LA MAQUINA PERO ESTA BLOQUEADA
```

Esta primera implementación, si bien es funcional, no puede escalar a manejar múltiples estados al menos que modifiquemos las comparaciones por chequeos en arrays de estados que habría que manejar u otro cambio que surja. Además, ¡ha sido mucho código! El problema del torniquete es un problema resuelto miles de veces, así que es casi como si estuviésemos re-escribiendo la rueda. Veamos como se vería usando [aasm](https://github.com/aasm/aasm) y una máquina de estados propiamente dicha:

```ruby
require 'aasm'

class Turnstile
  include AASM

  aasm do
    state :locked, :initial => true
    state :unlocked

    event :insert_coin do
      transitions :from => :locked, :to => :unlocked

      after { puts "insert: SE COLOCA UNA MONEDA" }
      error { puts "insert: SE COLOCA LA MONEDA PERO NADA PASA" }
    end

    event :push_handle do
      transitions :from => :unlocked, :to => :locked

      after { puts "push: DESBLOQUEANDO EL CAMINO" }
      error { puts "push: SE EMPUJO LA MAQUINA PERO ESTA BLOQUEADA" }
    end
  end
end

turnstile = Turnstile.new
turnstile.insert_coin # insert: SE COLOCA UNA MONEDA
turnstile.push_handle # push: DESBLOQUEANDO EL CAMINO
turnstile.push_handle # push: SE EMPUJO LA MAQUINA PERO ESTA BLOQUEADA
turnstile.insert_coin # insert: SE COLOCA UNA MONEDA
turnstile.push_handle # push: DESBLOQUEANDO EL CAMINO
turnstile.push_handle # push: SE EMPUJO LA MAQUINA PERO ESTA BLOQUEADA
```

Simple, ¿no? ¡No tenemos condicionales! Eso hace que realmente no tengamos muchos branches de ejecución (`if`, `else`, `case`) y hayamos evitado mucha complejidad. Toda esta simpleza proviene de 3 conceptos básicos en una máquina de estados y de 1 concepto que la gema coloca como conveniencia. Partamos de los 3 conceptos básicos:

- **Estado**: Es el estado en que puede estar algo. Sólo un estado a la vez. En este caso: `:locked` y `:unlocked`.
- **Evento**: Un evento es un acontecimiento que modifica el estado de la máquina de estados. Todo alteramiento del estado debería pasar a través de un evento. En este caso nuestros eventos son `:insert_coin` y `:push_handle`.
- **Transición**: Una transición es el cambio en sí de un estado a otro, siempre gatillado en el contexto de un evento. La transición nos indica cuáles son los posibles estados finales a partir de un estado inicial. En este caso, ambos estados pueden pasar entre sí a través de dos eventos. Ésta es la más simple de las máquinas de estado

El otro concepto, agregado por la gema, es el de los `callbacks`, que son acontecimientos que ocurren cuando un evento pudo ocurrir (`after`) o falló en su intento (`error`). Muchas veces realmente los `callbacks` no son tan útiles porque podríamos estar colocando demasiado comportamiento en el modelo pero en este caso es bastante útil. Como un ejemplo adicional, voy a colocar aquí una forma simplificada de una máquina de estado que he usado últimamente para modelar un movimiento:

```ruby
aasm :column => :state do
  state :pending, :initial => true
  state :confirmed
  state :rejected

  event :confirm do
    transitions :from => :pending, :to => :confirmed
  end

  event :reject do
    transitions :from => :pending, :to => :rejected
  end

  event :rollback do
    transitions :from => :confirmed, :to => :rejected
  end
end
```

En este caso, el objeto podía quedar rechazado para siempre, así que, como si fuera un grafo, podríamos decir lo siguiente:

```txt
pending ----(confirm!)----> confirmed ----(rollback)----> rejected
pending --------------------(reject!)-------------------> rejected
```

No hay un camino hacia atrás y por ende nos aseguramos que no hay forma de convertir un movimiento rechazado en otra cosa. Podemos rechazar alguno ya confirmado pero tampoco podemos transformar un movimiento confirmado en uno pendiente.

## Usando Rails

El uso de AASM con Rails es casi idéntico a la explicación anterior. Lo primero y más importante es que `aasm` debería ir instalado en el `Gemfile`:

```ruby
gem 'aasm'
```

Segundo, tenemos que pasarle a `aasm` cuál es la columna que vamos a usar:

```ruby
class Turnstile < ActiveRecord::Base
  include AASM

  aasm :column => :state do
  end
end
```

Y tercero, hay que tener en cuenta que AASM nos entrega dos versiones de cada evento: una versión que sólo modifica el atributo y otra que lo guarda.

```ruby
turnstile = Turnstile.new
turnstile.insert_coin   # not saved
turnstile.insert_coin!  # saved
```

## Conclusión

En conclusión, usar una máquina de estados nos libra de mucha complejidad y nos da una buena forma de expresar reglas sobre cómo es que algo cambia de estado. Quizás a primera vista no parezca de mucho uso pero en la mayoría de casos en que tuve estados, requerí en algún momento de algunas reglas para el cambio de los estados y por ende terminé requiriendo una máquina de estados. Además, cada vez que tenemos 2 o más métodos booleanos indicando el estado de algo (`approved?`, `rejected?`, `pending?`), es muy posible que los que realmente necesitemos es una máquina de estados.

[1]: /images/turnstile.jpg
