---
layout: post
title: Herencia y Composición
author: juliogarciag
tags:
    - oop
    - ruby
---
Antes de embarcarnos en explicar qué es la composición, hay que explicar el por qué de este post. La idea es entender *qué* es la composición y por qué existe la frase (extraída del libro [Design Patterns](https://en.wikipedia.org/wiki/Design_Patterns)):

> Favor 'object composition' over 'class inheritance'.

Pensemos primero en un problema: Tenemos una función de un chat que recibe un mensaje (quien sabe cómo aunque puede ser por websockets o por long polling) y debe notificarlo inmediatamente a varios lugares:

```ruby
class Notifier
  def initialize(raw_message)
    self.raw_message = raw_message
  end

  def send_notifications
    send_by_websockets(create_event_for_websockets)
    notify_third_party_service(raw_message)
  end

  private

  attr_accessor :raw_message

  def send_by_websockets
    # ...
  end

  def create_event_for_websockets
    # ...
  end

  # ... more private methods
end
```

Unas semanas después, tenemos que implementar una feature super genial que lee frases tipo: *I want 1 cup of coffee* que sean enviadas a ciertos usuarios especiales (bots) y generen órdenes de compra de varios bienes y servicios. Sabemos que tenemos que parsear esa data y sabemos que esto puede resultar complicado, así que creamos un **mixin** usando un módulo:

```ruby
module OrderSender
  def send_orders_from_message
    # ...
  end
end

class Notifier
  include OrderSender

  # ...

  def send_notifications
    send_orders_from_message
    send_by_websockets(create_event_for_websockets)
    notify_third_party_service(raw_message)
  end

  # ...
end
```

Luego realizamos la feature en el módulo que fue incluido. Con el tiempo nos encontramos con que deberíamos testear esto. Si de todos modos el mensaje en raw es una cadena codificada, entonces deberíamos ser capaces de realizar tests unitarios que nos ayuden a no romper ninguna funcionalidad y a descubrir posibles errores. Así que empezamos:



```ruby
describe OrderSender do
  describe "#send_orders_from_message" do
  end
end
```

Y aquí nos detenemos un minuto: ¿Cómo testeamos un módulo? Tenemos que crear un objeto para incluirlo y luego poder usarlo, algo así:

```ruby
describe OrderSender do
  describe "#send_orders_from_message" do
    it "recognizes messages and set them to somewhere else" do
      object = Object.new
      object.send(:extend, OrderSender)
    end
  end
end
```

Y en la prueba nos damos cuenta que nos hemos olvidado del `raw_message`, así que tenemos que crear una clase completa que pueda tener ese mensaje o usamos un [doble](https://adamcod.es/2014/05/15/test-doubles-mock-vs-stub.html):

```ruby
describe OrderSender do
  describe "#send_orders_from_message" do
    let(:raw_message) do
      { data: "i want 1 cup of coffee", more_attributes: "..." }
    end

    it "recognizes messages and set them to somewhere else" do
      object = double(raw_message: raw_message)
      object.send(:extend, OrderSender)
    end
  end
end
```

Ahora que hemos logrado tener algo que testear, nos damos cuenta que no tenemos cómo comprobar que hemos creado o no órdenes. Si bien hemos sido precavidos y cada servicio que representa una tienda que venda un producto está encapsulado en su propia clase, no tenemos cómo hacer esa comprobación. Es más, no tenemos cómo evitar que los tests creen órdenes de compra *reales* de los productos. ¡Podríamos comprar toneladas de café sin darnos cuenta!

Entonces nos calmamos y recordamos que podemos usar [stubs](https://adamcod.es/2014/05/15/test-doubles-mock-vs-stub.html#stubs). Hacer *stub* de un método significa reescribir el método con una implementación falsa durante un tiempo, de tal forma que podemos hacer algo así:

```ruby
allow(Time).to receive(:now).and_return(Time.new(2015, 12, 25))
expect(date_service.christmas?).to eq(true)
```

Podríamos usar stubs para sobreescribir los métodos de los servicios que vamos a usar en la clase:

```ruby
describe OrderSender do
  describe "#send_orders_from_message" do
    let(:raw_message) do
      { data: "i want 1 cup of coffee", more_attributes: "..." }
    end
    let(:fake_coffee_service) { double }
    let(:object) { double(raw_message: raw_message) }

    before do
      object.send(:extend, OrderSender)
      allow(CoffeeService).to receive(:new).and_return(fake_coffee_service)
      allow(fake_coffee_service).to receive(:order).and_return(success: true)
    end

    it "can send 1 cup of coffee" do
      object.send_orders_from_message
      expect(fake_coffee_service).to have_received(:order).with([
        { product: "cup of coffee", amount: 1 }
      ])
    end
  end
end
```

Podemos decir que tenemos un buen test y ser felices. Sin embargo, el test tiene varios aspectos más complejos de lo deseado:

- Tenemos que usar dobles constantemente.
- Tenemos que hacer stubs de todo lo que tengamos.
- No podemos llamar a `object.send_orders_from_message` más de una vez por test puesto que los stubs se romperían. No es un gran problema ahora pero limita lo que podemos hacer, como la capacidad de no permitir que se envíe un pedido de un café más de 5 veces seguidas. Podríamos hacer esa feature pero testearla va a requerir de buscar un workaround.
- Es muy fácil olvidar un stub de algún servicio y enviar un producto de todos modos.

Creo que podríamos hacerlo mejor con una implementación alternativa...



## Alternativa: No usar mixins

La otra alternativa es, además de botarlo todo y decidir que los tests no valen la pena, no usar mixins. Hay que entender primero que los mixins no son más que una implementación de la herencia múltiple en ruby. Es como si estuviésemos heredando de muchas clases y por ende tenemos los mismos problemas que con la herencia múltiple en otros lenguajes (como C o Python), como problemas de choque de nombres o falta de aislamiento en los contextos de cada padre, puesto que ahora todos dependen entre sí. No puedes simplemente definir un método privado `perform_task` porque hay chances de que otro mixin lo implemente también.

Además, los mixins son - como habrás visto hace un momento - más complicados de testear que un objeto común y silvestre. La herencia amarra objetos entre sí de una forma demasiado fuerte y no permite fácilmente inyectar dependencias dentro de cada cosa que testeamos. Además, al testear un módulo no estamos testeando un módulo sino un objeto que incluye el módulo. Tenemos que ser muy explícitos en los tests sobre cómo construir ese objeto mientras que en el código el mixin no tiene básicamente conocimiento real de la estructura de ese objeto.

Pensemos entonces en cómo implementaríamos esto con un objeto normal:

```ruby
class MessageOrderSender
  def initialize(message_content)
    self.message_content = message_content
  end

  def send_orders
    # ... logic to send the orders
  end

  private

  attr_accessor :message_content
end

class Notifier
  # ...

  def send_notifications
    send_orders_from_message
    send_by_websockets(create_event_for_websockets)
    notify_third_party_service(raw_message)
  end

  private

  def send_orders_from_message
    # Yep... A plain old ruby object! :)
    sender = MessageOrderSender.new(raw_message[:message])
    sender.send_orders
  end

  # ...
end
```

Ahora testeemos esto nuevamente. Comencemos por el setup del objeto a testear:

```ruby
describe MessageOrderSender do
  describe "#send_orders" do
    let(:message_content) { "i want 1 cup of coffee" }
    let(:sender) { MessageOrderSender.new(message_content) }

    it "can send 1 cup of coffee" do
      sender.send_orders
    end
  end
end
```

Si bien el setup ha sido más simple y natural, tenemos el mismo problema que antes: vamos a hacer pedidos de café aunque no queramos. Una solución a esto es usar **inyección de dependencias** para incluir estos servicios. Para eso modificaremos el constructor de nuestra clase testeada:

```ruby
class MessageOrderSender
  def initialize(message_content, coffee_service: nil, pizza_service: nil)
    self.message_content = message_content
    self.coffee_service = coffee_service || CoffeeService.new
    self.pizza_service = pizza_service || PizzaService.new
  end

  def send_orders
    # ... logic to send the orders if the message says so
  end

  private

  attr_accessor :message_content, :coffee_service, :pizza_service
end
```

Una vez que las dependencias de esta clase están preparadas para ser ingresadas en el constructor, podemos simplemente usar esto para inyectar algunos [dobles](https://semaphoreci.com/community/tutorials/mocking-with-rspec-doubles-and-expectations), que nos ayudarán a no necesitar crear las dependencias reales que necesitamos. 

```ruby
describe MessageOrderSender do
  describe "#send_orders" do
    let(:fake_coffee_service) { double }
    let(:message_content) { "i want 1 cup of coffee" }
    let(:sender) do
      MessageOrderSender.new(
        message_content,
        coffee_service: fake_coffee_service
       )
    end

    before do
      allow(fake_coffee_service).to receive(:order).and_return(success: true)
    end

    it "can send 1 cup of coffee" do
      sender.send_orders
      expect(fake_coffee_service).to receive(:order).with([
        { product: "cup of coffee", amount: 1 }
      ])
    end
  end
end
```

No sólo el test es más simple sino que es más natural para escribir y tiene algunas ventajas:

- No estamos intentando extender un objeto dinámicamente (algo que no se puede hacer en todos los lenguajes, dicho sea de paso)
- No estamos usando muchos más dobles de lo normal (en realidad tenemos tantos dobles como dependencias ahora)
- Estamos testeando un objeto directamente y podríamos usar `subject` y `is_expected_to` de RSpec para hacer el test más conciso aún. (aunque no ahora, pero abrimos la posibilidad)

Sin embargo… todavía tenemos un problema: Si alguien olvida hacer `stub` de un nuevo servicio, nuestros tests harán una compra. Por ejemplo, en este último test *olvidamos* el `pizza_service`. Si lo corremos ahora, ¡compraremos un montón de pizza!

El problema fue que pusimos un valor por defecto para el servicio de pizzas:

```ruby
self.pizza_service = pizza_service || PizzaService.new
```

Lo hicimos para no tener que pasar todos los servicios como argumentos en `Notifier`, pero realmente necesitamos evitar este problema, así que primero vamos a hacer requeridos estos argumentos en el constructor `MessageOrderSender`:

```ruby
def initialize(message_content, coffee_service:, pizza_service:)
  self.message_content = message_content
  self.coffee_service = coffee_service
  self.pizza_service = pizza_service
end
```

> **TIP**: Si pones el keyword argument como `keyword:` y sin nada después, el keyword argument se vuelve requerido.

Esto nos salva en los tests pero nos rompe el notificador, así que vamos a mandar estos parámetros en el método `send_orders_from_message` del `Notifier`:

```ruby
def send_orders_from_message
  sender = MessageOrderSender.new(
    raw_message[:message],
    coffee_service: CoffeeService.new,
    pizza_service: PizzaService.new
  )
  sender.send_orders
end
```

El problema con esto es que cada vez que querramos usar `MessageOrderSender` tendremos que pasar todos los argumentos, incluso cuando probemos o realicemos debug. Una solución simple es proveer un [facade](https://en.wikipedia.org/wiki/Facade_pattern) mediante un método nuevo en `MessageOrderSender`:

```ruby
class MessageOrderSender
  def self.send_standard_orders(message)
    sender = new(
      message,
      coffee_service: CoffeeService.new,
      pizza_service: PizzaService.new
    )
    sender.send_orders
  end
  # ...
end

class Notifier
  def send_orders_from_message
    MessageOrderSender.send_standard_orders(raw_message[:message])
  end
end
```

## Conclusión

En los dos casos que hemos discutido, hemos visto las diferencias entre aplicar herencia mediante mixins y usar composición de objetos aplicando inyección de dependencias. La idea en general es que siempre que se tenga un problema, primero busquemos solucionarlo mediante la creación de objetos normales y, sólo si es que la situación lo amerita, usar herencia. La razón es porque los objetos normales son más simples y reutilizables que los mixins a pesar del nombre de los mixins.