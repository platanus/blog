---
layout: post
title: 'SOLID: Liskov Substitution Principle'
author: arturopuente
tags:
    - oop
    - solid
    - ruby
---

El tercer principio SOLID es el de substitución de Liskov, que nos dice que las clases hijas deben poder ser utilizadas en reemplazo de una clase padre sin mayor modificación, la definición se entiende algo así:

> Un objeto de una subclase debe poder ser usado, junto a sus métodos y propiedades, en un lugar donde se espera un objeto de la clase de la cual desciende

Es decir, no deberían sobreescribir las definiciones de los métodos de esta forma, y los atributos deben ser del mismo tipo de dato para no romper la compatiblidad entre ambos:

```ruby
class Vehicle
  attr_accessor :latitude, :longitude
  
  def set_position(latitude, longitude)
    self.latitude = latitude
    self.longitude = longitude
  end
end

class Plane < Vehicle
  attr_accessor :altitude
  
  def set_position(latitude, longitude, altitude)
    self.latitude = latitude
    self.longitude = longitude
    self.altitude = altitude
  end
end
```

En este caso, la clase Plane es hija de Vehicle, pero redefine `set_position` para incluir la altura a la cuál está volando,, desligandose del principio y rompiendo la compatibilidad de la clase, por ejemplo:

```ruby
[Vehicle.new, Plane.new, Object.new].each do |e|
  e.set_position(20.22, -19.57) if e.is_a?(Vehicle)
end
```

La llamada de `set_position` a la instancia de Plane fallaría, puesto que espera un valor de altitude para ubicarse correctamente.

Esto nos lleva a una paradoja, si bien un avión es claramente un vehículo en el mundo real, el modelo conceptual orientado a objetos de un avión puede no caber perfectamente en el modelo conceptual representativo de un vehículo. Cómo podemos resolver esto?

### Usando valores por defecto

Una forma es asignarle a altitude un valor por defecto:

```ruby
class Vehicle
  attr_accessor :latitude, :longitude
  
  def set_position(latitude, longitude)
    self.latitude = latitude
    self.longitude = longitude
  end
end

class Plane < Vehicle
  attr_accessor :altitude
  
  def set_position(latitude, longitude, altitude = 0)
    super.set_position(latitude, longitude)
    self.altitude = altitude
  end
end

[Vehicle.new, Plane.new, Object.new].each do |e|
  e.set_position(20.22, -19.57) if e.is_a?(Vehicle)
end
```

Esto hará que la llamada a set_position funcione, y se puede acordar que altitud 0 significa que el avión está en tierra firme, sin embargo no es recomendado porque igualmente estamos cambiando la definición del método, es un parche en vez de una solución real.

### Usando un hash de parámetros

Otra solución viene por el lado de cambiar un poco la interfaz de ambos métodos, de forma que mantenemos la misma definición en padre e hijo

```ruby
class Vehicle
  attr_accessor :latitude, :longitude
  
  def set_position(position)
    self.latitude = position[:latitude] if position[:latitude]
    self.longitude = position[:longitude] if position[:longitude]
  end
end

class Plane < Vehicle
  attr_accessor :altitude
  
  def set_position(position)
    super.set_position(position)
    self.altitude = position[:altitude]
  end
end

[Vehicle.new, Plane.new, Object.new].each do |e|
  e.set_position({ latitude: 20.22, longitude: -19.57 }) if e.is_a?(Vehicle)
  e.set_position({ altitude: 9416 }) if e.is_a?(Plane)
end
```

Esto nos permite pasar parámetros adicionales en el hash de position, sin embargo, perdemos un poco la claridad en la definición del método `set_position`. La ventaja de esta solución es que podemos añadir nuevos parámetros al método en otras subclases de Vehicle sin cambiar el código de la clase padre.

### Separando el método en métodos más pequeños

Otra opción que tenemos es no utilizar el método `set_position` para asignar el valor de todas las propiedades, sino tener un setter propio para cada una:

```ruby
class Vehicle
  attr_accessor :latitude, :longitude
  
  def set_latitude(latitude)
    self.latitude = latitude
  end
  
  def set_longitude(longitude)
    self.longitude = longitude
  end
end

class Plane < Vehicle
  attr_accessor :altitude
  
  def set_altitude(altitude)
    self.altitude = altitude
  end
end

[Vehicle.new, Plane.new, Object.new].each do |e|
  e.set_latitude(20.22) if e.is_a?(Vehicle)
  e.set_longitude(-19.57) if e.is_a?(Vehicle)
  e.set_altitude(9416) if e.is_a?(Plane)
end
```

Aquí valor puede ser actualizado independientemente en el setter, así que limitamos el alcance de cada método para evitar que su definición pueda cambiar.

Este enfoque termina en código más verboso, pero nos brinda código más fácil de testear (hay menos efectos secundarios en cáda método) y entendible fuera de la definición de la clase.

## Consideraciones sobre los atributos

Algo a tener muy en cuenta es que el principio de Liskov también nos advierte sobre cambiar el valor de las propiedades hijas, por ejemplo:

```ruby
class Vehicle
  attr_accessor :speed
end

class Plane < Vehicle
end

vehicle = Vehicle.new
vehicle.speed = 20

plane = Plane.new
plane.speed = 65.0
```

En este caso, aunque ambos responden al valor de speed con un número, el vehículo usa un número entero y el avión un número decimal. Esto en lo posible debe evitarse, porque puede generar errores de compatiblidad.

En Ruby por ejemplo, si estamos calculando porcentajes, las operaciones con valores enteros nos pueden fallar.

```ruby
speed_limit = 80

vehicle = Vehicle.new
vehicle.speed = 20

plane = Plane.new
plane.speed = 65.0

(vehicle.speed / speed_limit) #=> Nos devuelve 0, en vez de 25
(plane.speed / speed_limit) #=> Nos devuelve 81.25
```

Una forma de solucionarlo puede ser declarar un atributo adicional en el hijo, que guarde el valor más preciso para usarlo en los cálculos

```ruby
class TopSpeedCalculator
  SPEED_LIMIT = 35
  
  def over_speed_limit?(speed)
    speed > SPEED_LIMIT
  end
  
  def speed_percentage(speed)
    # Sí, aquí se podría pasar SPEED_LIMIT a un valor decimal también :P
    (speed / SPEED_LIMIT) * 100
  end
end

class Vehicle
  attr_accessor :speed
end

class Plane < Vehicle
  attr_accessor :precise_speed
end

calculator = TopSpeedCalculator.new

vehicle = Vehicle.new
vehicle.speed = 20

calculator.over_speed_limit?(vehicle.speed) #=> false 
calculator.speed_percentage(vehicle.speed) #=> 0 

plane = Plane.new
plane.speed = 65
plane.precise_speed = 65.0

calculator.over_speed_limit?(plane.speed) #=> true 
calculator.speed_percentage(plane.speed) #=> 300 (65 / 20 resulta en 3)
calculator.speed_percentage(plane.precise_speed) #=> 325
```

