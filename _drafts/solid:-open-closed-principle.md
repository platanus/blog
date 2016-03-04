---
layout: post
title: 'SOLID: Open/Closed Principle'
author: juliogarciag
tags:
    - oop
    - solid
    - ruby
---

El principio menos sencillo de traducir al español es una de las directrices más importantes a la hora de diseñar sistemas que puedan adaptarse a cambios. El principio de open/closed puede simplificarse en esta frase, que fácilmente puede sonar a un anhelo inalcanzable:

> "Software entities (classes, modules, functions, etc.) should be open for extension, but closed for modification."

Lo que nos dice este principio es que toda estructura que contenga algún algoritmo debería ser hecha de tal modo que debería ser posible agregar funcionalidad sin necesidad de modificar el algoritmo.

En realidad el dicho es más una directriz que algo específico: Deberíamos ser capaces de agregar funcionalidad a un programa cambiando la mínima cantidad posible de código. Este principio se encuentra en el centro de muchas decisiones de diseño y de muchos patrones de diseño orientado a objetos.

## Ejemplo: Estrategias

Imaginemos un sistema que recibe de un sistema externo la notificación de que un pago a una cuenta de ahorros ha sido realizado. Este pago servirá para finalizar una compra hecha en una tienda virtual. Podríamos diseñar esta clase receptora del siguiente modo:

```ruby
class Receptor
  def receive(payment)
    order = Order.find_by!(state: "pending", payment_id: payment.id)
    if order.total == payment.total
      order.update(state: "completed")
    end
  end
end
```

Y con eso tendríamos nuestra feature completa. Sin embargo, a la semana siguiente se nos ocurrió que también podemos usar este sistema de pagos para recibir pagos de proveedores. Ahora nuestro receptor tiene que encargarse de ello también. Imaginemos que simplemente *modificamos* directamente la clase para abarcar esta nueva feature:

```ruby
class Receptor
  def receive(payment)
    order = Order.find_by(state: "pending", payment_id: payment.id)
    if order.present?
      order.update(state: "completed") if order.total == payment.total
    else
      ProviderPayment.create!(
        provider_id: payment.metadata["provider_id"],
        payment_id: payment.id
      )
    end
  end
end
```

Pronto nos enteramos que debemos mandar un correo a alguien si es que la orden ha sido pagada sólo parcialmente. También queremos que cuando un proveedor reciba un pago, si es que el pago supera un presupuesto, un usuario recibirá un mensaje. Además, si es que no hay información de un proveedor o el pago no pertenece a un pedido, deberá registrarse este pago fantasma. Nos hemos llenado de features y nuestra clase puede llegar a tener muchas más líneas de lo esperado una vez que hayamos implementado todo. El hecho de que tengamos muchas features en un sólo archivo es también una violación del principio de una responsabilidad, pero obviemos ese detalle por ahora. El hecho de que tengamos varias acciones en una misma clase *implica que no podemos hacer un cambio no trivial en una acción sin antes testear que no hayamos roto todo lo anterior*.

Por ende, necesitamos poder extender la funcionalidad del receptor de pagos sin modificar las funcionalidades que hemos agregado previamente. Hay varias formas de lograrlo, pero en definitiva todas aspuntan a lo mismo: Independizar cada interacción.

Una solución es usar el patrón estrategia. Por ejemplo, podríamos mover las actividades correspondientes a lo que hay que hacer con cada tipo de entidad a su propia clase:

```ruby
# receptor.rb
class Receptor
  def receive(payment)
    order = find_order(payment)
    specific_receptor = if order.present?
      OrderReceptor.new(order: order)
    elsif payment.metadata["provider_id"].present?
      ProviderPaymentReceptor.new(provider_id: payment.metadata["provider_id"])
    else
      UnknownPaymentReceptor.new
    end

    specific_receptor.receive_payment(payment)
  end

  private

  def find_order(payment)
    Order.find_by(state: "pending", payment_id: payment.id)
  end
end
```

Cada una de las 3 clases específicas (`OrderReceptor`, `ProviderPaymentReceptor` y `UnknownPaymentReceptor`) son en realidad estrategias. Cada una vivirá por separado y podrá testearse por su cuenta. Podríamos extender la funcionalidad de cada estrategia independientemente de la otra. Por ende, enviar las notificaciones esperadas cuando se recibe un pago de proveedor no afectará lo que ocurrirá con las otras recepciones. De este modo, hemos aligerado el riesgo de cada feature puesto que hemos logrado 3 cosas:

- Como el alcance de cada estrategia no es intimidante y la lógica es más aislada, podremos testear más casos borde de cada estrategia. En lugar de tener 40 tests en un archivo, podemos tener 15 tests en cada uno de los 3 archivos de tests de cada estrategia. De este modo estamos incentivando la testeabilidad de nuestras features.
- Podemos agregar mayor cantidad de métodos privados en cada estrategia, dividiendo y modularizando lo que ya tenemos sin correr el riesgo de terminar con una clase dios.
- Como el alcance ha sido dividido, es más sencillo para nosotros - humanos - pensar en cada caso. Una clase muy grande es psicológicamente más intimidante que 3 clases pequeñas y es más complicado de compartir y de entender para otros programadores.

## Conclusión

Hay otros ejemplos de aplicación del principio de open/closed en librerías que usamos todos los días: por ejemplo, [Pundit](https://github.com/elabs/pundit) separa la lógica de autorización en varias clases independientes llamadas policies, a diferencia de [CanCan](https://github.com/ryanb/cancan), donde la lógica de autorización se encuentra en un único archivo que posee un DSL. Sin una división adicional, el patrón usado en CanCan puede llevarnos a tener una clase de cientos de líneas de código lleno de casos bordes.

Otro ejemplo es el de la creación de servicios a partir de casos de uso. Por ejemplo, si tenemos un servicio llamado `ProductCreation` que es llamado desde el controlador, modificar algo relacionado a la creación de un producto iría aquí y no sería necesario modificar un controlador que posiblemente incluya los puntos de entradas de más casos de uso. Los objetos de servicios nos proveen de la encapsulación necesaria para tener código extensible que requiera una mínima cantidad de cambios en la base de código existente.
