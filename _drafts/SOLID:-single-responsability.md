---
layout: post
title: "SOLID: Single Responsability"
author: juliogarciag
tags:
    - oop
    - solid
    - ruby
---

SOLID es un acrónimo que se refiere a 5 principios de programación orientada a objetos **(POO)**, presentados por [Robert Martín](https://en.wikipedia.org/wiki/Robert_Cecil_Martin) hace ya muchos años. Son 5 principios dedicados al diseño de clases y son guías importantes para no sólo programar mejor y diseñar mejores redes de objetos, sino que son la base para poder crear patrones que fortalezcan estos principios.

Bueno, dicho esto diré sus quizás terroríficos, o sólo raros, nombres:

1. Single Responsability Principle
2. Open/Closed Principle
3. Liskov Substitution Principle
4. Interface Segregation Principle
5. Depedency Inversion Principle

Más allá de los nombres extraños de algunos de estos principios y de los nombres demasiado obvios de otros, los 5 principios nos ayudarán a escribir código más flexible y mantenible. Hay que tener en cuenta que esto último es su objetivo principal. Los principios no existen necesariamente para ayudarnos a escribir código nuevo más rápidamente, sino para escribir código que otro programador (o nuestro yo del futuro) pueda modificar o reparar fácilmente. Incluso, en muchos casos, deberemos demorar más en comenzar a escribir algo de código para poder modificarlo más fácilmente en el futuro.

Es importante notar que queda a nuestro criterio, y al criterio del proyecto, qué tan flexible queremos que sea lo que estamos haciendo.

Para comenzar, hablemos del primer principio: Single Responsability, o **SRP** para los amigos.

## Single Responsability

El principio de la única responsabilidad es quizás el más importante y el más simple de entender, lo que no lo hace necesariamente el más fácil de utilizar. El principio nos dice que una clase u objeto debe tener únicamente una responsabilidad.

Si pensáramos en nuestros objetos como trabajadores de una empresa virtual que se comunican entre sí, SRP es la ley que nos dice que nadie debe hacer más de una cosa a la vez. Si tenemos un trabajador encargado de 3 cosas a la vez, va a ser más complicado saber en qué se equivocó cuando lo hizo y va a ser más engorroso entender qué es lo que está haciendo.

Por ejemplo, veamos la siguiente clase:

```ruby
class User
  def full_name
    # ...
  end

  def notify_external_system
    # ...
  end

  def register_payment_card
    # ...
  end
end
```

Aunque éste parece el típico layout de una clase de usuario en un sistema donde las 3 funcionalidades de los 3 métodos son importantes, esta clase viola el principio de la única responsabilidad porque ahora la misma clase se encarga de 3 cosas: decir el nombre completo de un usuario, notificar a un sistema externo de algo y registrar la tarjeta de crédito de ese mismo usuario.

Es como tener un trabajador que realiza 3 cosas con las mismas herramientas. ¿Por qué la metáfora? Cada clase en OOP encapsula no sólo código sino también estado: variables, métodos y nombres. A la hora en que esta clase realiza 3 cosas, la clase `User` tendrá que mantener el estado de 3 funcionalidades. Esto es molesto para mantener porque debemos cuidarnos de no colapsar nombres y cuidar que nuestros métodos no se estrellen entre sí gracias a callbacks u otro tipo de llamadas. Además, visualmente pueden ser demasiado complejas de comprender si la clase llega a crecer fuera de ciertos límites. Por otro lado, todas las funcionalidades deberán testearse juntas, lo que vuelve a limitar lo que podemos hacer.

Un diseño donde cada funcionalidad hace sólo una cosa permite más granularidad al programador y en potencia puede darle más libertad a nueva funcionalidad. Veamos un refactor:

```ruby
class User
  def full_name
    # ...
  end
end

class ExternalSystemNotification
  attr_accessor :user

  def initialize(user)
    self.user = user
  end

  def notify
  end
end

class PaymentCard
  attr_accessor :user

  def initialize(user)
    self.user = user
  end

  def register
    # ...
  end
end
```

Este segundo ejemplo puede parecer over-engineered, más largo y más tedioso de escribir, pero estos puntos son sólo estéticos. La ventaja es que este nuevo diseño separa cada funcionalidad en su propia clase, liberando cada funcionalidad de la clase `User`. Curiosamente, es como si cada funcionalidad pudiese ahora hacer más cosas. Cada funcionalidad puede hacer su trabajo sin miedo de chocar entre sí: El programador va a poder crear variables de instancia y métodos sin miedo de chocar con los de la clase `User` y cada una las clases será más fácil de leer puesto que sólo se encarga cada parte de una sola cosa.

Ésta es el principal principio de SOLID y es la base de todo lo que venga a futuro en diseño orientado a objetos, incluyendo los demás principios. Definiendo una responsabilidad por clase u objeto podemos aislar responsabilidades y reducir la complejidad  de nuestro sistema. Incluso hay algunos patrones de diseño orientado a objetos que provienen de la aplicación directa de este principio, como el [patrón decorador][1], el [patrón comando][2] y el [patrón factoría][3]. Además, cada vez que aplicamos técnicas como el uso de [query objects][4], [service objects][5], [value objects][6] o [serializers][7] estamos haciendo uso del principio de Single Responsability para dividir nuestro código desacopladamente.

Para última muestra de que en realidad casi todos estos patrones son la misma aplicación de SRP, un botón:

```ruby
# un query object:
Queries::ProductsPaidWithOrdersQuery.new(user).result
# un service object:
Services::PaymentProcessingService.new(user).process
# un decorador
Decorators::GithubUserDecorator.new(user).repositories
# una factoria
Factories::MonsterFactory.new(user).create_monster
# un comando
Commands::CalculateTotalSpent.new(user).total
# un value object
Values::FullName.new(user).value
# un serializer
UserSerializer.new(user).as_json
```

[1]: https://es.wikipedia.org/wiki/Decorator_(patr%C3%B3n_de_dise%C3%B1o)
[2]: https://es.wikipedia.org/wiki/Command_(patr%C3%B3n_de_dise%C3%B1o)
[3]: https://es.wikipedia.org/wiki/Factory_Method_(patr%C3%B3n_de_dise%C3%B1o)
[4]: http://blog.codeclimate.com/blog/2012/10/17/7-ways-to-decompose-fat-activerecord-models/#query-objects
[5]: http://blog.codeclimate.com/blog/2012/10/17/7-ways-to-decompose-fat-activerecord-models/#service-objects
[6]: http://blog.codeclimate.com/blog/2012/10/17/7-ways-to-decompose-fat-activerecord-models/#value-objects
[7]: https://github.com/rails-api/active_model_serializers
