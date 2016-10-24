---
layout: post
title: Explorando los Custom Matchers de RSpec
author: arturopuente
tags:
  - ruby
  - rspec
  - code
  - rails
  - testing
---

Un custom matcher nos permite definir una condición de prueba que puede ser reutilizada:

```ruby
RSpec.describe User, type: :model do
  describe "associations" do
    # este have_many es un custom matcher!
    it { should have_many(:shipments) }
  end
end
```

Es muy útil para ayudarnos a reducir la complejidad y repetición de código en nuestros tests. Veamos el siguiente caso:

Tenemos un servicio `OrderPlacementService` que toma un usuario y una orden, al momento de ejecutarse, se crea un `Shipment` asociado al usuario. Este envío tiene el estado de `confirmed` y un tiempo referencial de dos semanas. Podemos testear esto de la siguiente manera:

```ruby
let(:user) { create(:user) }
let(:order) { create(:order) }
let(:service) { OrderPlacementService.new(order, user) }

it "should associate a confirmed shipment to the user" do
  service.perform
  expect(user.shipments.last.status).to eq(:confirmed)
end

it "should set the delivery date to 2 weeks from now" do
  service.perform
  expect(user.shipments.last.delivered_at).to eq(2.weeks.from_now)
end
```

En este caso, al preguntar los envíos que le corresponden al usuario estamos repitiendo `user.shipments.last`, que podemos mover a una variable:

```ruby
it "should associate a confirmed shipment to the user" do
  service.perform
  shipment = user.shipments.last
  expect(shipment.status).to eq(:confirmed)
end
```

E incluso podríamos moverlo a un `let`, pero esto se hace engorroso a medida que añadimos más tests y más datos entran en juego.

Veamos otra opción, definir nuestros propios matchers de RSpec:

```ruby
RSpec::Matchers.define :have_shipment_status do |expected|
  match do |user|
    # Aquí definimos el valor de @actual, que podemos
    # usar posteriormente en otros bloques
    @actual = user.shipments.last.status
    user.shipments.last.status == expected
  end

  # Mensaje de error para expec(object).to
  failure_message_for_should do |actual|
    "expected that the user's latest shipment status: #{actual} would be equal to #{expected}"
  end

  # Mensaje de error para expec(object).to_not
  failure_message_for_should_not do |actual|
    "expected that the user's latest shipment status: #{actual} would not be equal to #{expected}"
  end

  description do
    "have a shipment status of #{expected}"
  end
end
```

Veamos cómo aplicaríamos esto al caso anterior:

```ruby
it "should associate a confirmed shipment to the user" do
  service.perform
  expect(user).to have_shipment_status(:confirmed)
end
```

Ahora podemos definir otro para la fecha de delivery:

```ruby
RSpec::Matchers.define :have_deliveries_within do |expected|
  match do |user|
    @actual = user.shipments.last.delivered_at
    user.shipments.last.delivered_at > expected
  end

  failure_message_for_should do |actual|
    "expected that the user's latest shipment delivery date: #{actual} would be equal to #{expected}"
  end

  failure_message_for_should_not do |actual|
    "expected that the user's latest shipment delivery date: #{actual} would not be equal to #{expected}"
  end

  description do
    "have a shipment delivery date of #{expected}"
  end
end
```

Este matcher ahora reemplaza a la condición que teníamos previamente, resultando en código más legible y mantenible:

```ruby
it "should associate a confirmed shipment to the user" do
  service.perform
  expect(user).to have_shipment_status(:confirmed)
end

it "should set the delivery date to 2 weeks from now" do
  service.perform
  expect(user).to have_deliveries_within(2.weeks.from_now)
end
```
