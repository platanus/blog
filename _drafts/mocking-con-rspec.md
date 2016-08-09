---
layout: post
title: Mocking con RSpec
author: ldlsegovia
tags:
  - RSpec
  - Testing
---

En líneas generales, un mock puede entenderse como un objeto falso que se para en el lugar de uno real, simulando su comportamiento.
En RSpec, estos se utilizan para facilitar, o incluso posibilitar, las pruebas de objetos que interactúan con otros que tienen características que hacen difícil o imposible esta tarea.

En general, los objetos candidatos a ser "mockeados" suelen tener alguna de las siguientes características:

- Devuelven resultados no determinísticos (por ejemplo la hora o la temperatura).
- Tienen estados difíciles de crear o reproducir (por ejemplo errores de conexión).
- Son lentos (por ejemplo el resultado de un cálculo intensivo).
- Son interfaces a APIs de terceros.

Para entender mejor lo que un mock hace, voy a mostrarles una implementación básica que saqué del libro [RSpec Essentials](http://shop.oreilly.com/product/9781784395902.do)

```ruby
class Object #1
  def self.mock(method_name, return_value)
    klass = self
    existing_method = if klass.method_defined?(method_name) #2
                        klass.instance_method(method_name)
                      else
                        nil
                      end
    klass.send(:define_method, method_name) do |*args| #3
      return_value
    end

    yield if block_given? #4
  ensure
    if existing_method #5
      klass.send(:define_method, method_name, existing_method)
    else
      klass.send(:remove_method, method_name)
    end
  end
end
```

En el ejemplo, marqué cada uno de los pasos con un número. A continuación, explicaré que sucede en cada paso:

1. Se extiende la clase `Object` con el método `mock`. Es decir, que a partir de ahí, todas las clases podrán utilizar la funcionalidad de mock.
2. Se pregunta si la clase actual (la clase donde se está ejecutando `mock`), tiene definido el método de nombre contenido en `method_name`. De ser así, almacena su definición en la variable `existing_method`.
3. Una vez que se persistió la definición del método original, esta se reemplaza por una falsa que viene de la variable `return_value`. Aquí es donde efectivamente se hace el mock. Es decir, se reemplaza la lógica original con algo que sirva al propósito del test.
4. Ejecuta el contenido del bloque en el contexto del mock.
5. Una vez que se termina la ejecución, `ensure` asegura que se restablezca la definición original del método.

Así se ve puesta en práctica:

```ruby
class Product
  def price
    1000
  end
end

RSpec.describe Product do
  let(:product) { Product.new }

  it "returns mocked price" do
    Product.mock(:price, 2000) do
      expect(product.price).to eq(2000)
    end
  end

  it "returns default price" do
    expect(product.price).to eq(1000)
  end
end
```

Para nuestra fortuna, RSpec, viene con un conjunto de herramientas que nos permiten manejar este tema de manera simple y elegante sin tener que recurrir a una implemetanción propia. A continuación, mostaré como utilizar algunas de ellas pero antes, voy a complejizar el ejemplo para poder explicarlas mejor.

```ruby
class ShoppingCart
  def products
    # Se conecta con un API y en base al resultado obtenido,
    # arma un array de Products y lo retorna.
  end

  def total_price
    products.inject(0) do |sum, product|
      sum + product.price
    end
  end
end

class Product
  def price
    1000
  end
end
```

### `allow_any_instance_of`

Este método, hace más o menos lo mismo que hice en la implementación propia...

```ruby
RSpec.describe ShoppingCart do
  describe "#total_price" do
    it "returns the sum of the prices of all products" do
      num_products = 2
      cart = ShoppingCart.new
      some_products = [Product.new] * num_products

      allow_any_instance_of(ShoppingCart).to(
        receive(:products).and_return(some_products))
      expect(cart.total_price).to eq(num_products * 1000)
    end
  end
end
```

Como se puede ver, hago un mock del método de instancia `products` de `ShoppingCart` y le hago devolver un array de `Product`s como haría el original. Al final, verifico que el precio total sea igual a la cantidad de productos que pasé al mock por el precio del producto. De esta manera, pude probar el método `total_price` sin tener que conectarme al API que trae los verdaderos productos, evitando todos los problemas que esto acarrea.

`allow_any_instance_of` viene con su análogo `allow` que brinda la misma funcionalidad, pero para utilizar con cualquier tipo de objeto. Por ejemplo, suponiendo que `products` y `total_price` ahora son métodos de clase en `ShoppingCart` el test quedaría así:

```ruby
RSpec.describe ShoppingCart do
  describe "#total_price" do
    it "returns the sum of the prices of all products" do
      num_products = 2
      some_products = [Product.new] * num_products

      allow(ShoppingCart).to receive(:products).and_return(some_products)
      expect(ShoppingCart.total_price).to eq(num_products * 1000)
    end
  end
end
```

### `expect_any_instance_of`

Este método es igual que el anterior aunque, la diferencia, es que `expect_any_instance_of` exige que el método que hemos "mockeado", sea llamado durante el test. Siguiendo el ejemplo...

```ruby
RSpec.describe ShoppingCart do
  describe "#total_price" do
    it "returns the sum of the prices of all products" do
      # ...
      allow_any_instance_of(ShoppingCart).to(
        receive(:products).and_return(some_products))
      # No se llama a cart.total_price
    end
  end
end
```

El código anteriror, no produce errores al ejecutarse. En cambio, si reemplazamos `allow_any_instance_of` por `expect_any_instance_of`, el ejecutar el siguiente código mostraría el error: `Exactly one instance should have received the following message(s) but didn't: products`.

```ruby
RSpec.describe ShoppingCart do
  describe "#total_price" do
    it "returns the sum of the prices of all products" do
      # ...
      expect_any_instance_of(ShoppingCart).to(
        receive(:products).and_return(some_products))
      # No se llama a cart.total_price
    end
  end
end
```

Para evitar falsos positivos, es que se recomienda el uso de `expect_any_instance_of` por sobre `allow_any_instance_of`.
Recuerda que al igual que sucede con `allow_any_instance_of`, `expect_any_instance_of` tiene su análogo `expect` para utilizar con cualquier tipo de objeto.

### `double`

Supongamos que no es tan sencillo crear instancias de `Product` para construir el mock como hicimos en la línea: `some_products = [Product.new] * num_products`. Supongamos que hacerlo, implica complejizar el test pasando atributos con ciertos valores necesarios para que no se produzcan, por ejemplo, excepciones por validación. Cuando esto ocurre, es decir, cuando tenemos objetos complejos con estados difíciles de reproducir, se hace útil el uso de dobles. Un doble, es justamente eso, es un objeto falso que se para en lugar de uno real. Es decir, un mock. En nuestro ejemplo anterior, se observa que lo que realmente interesa de `Product` no es más que su método `price`. Con el poder del método `double` que nos proporciona RSpec, podemos reemplazar a `Product` por un doble, de la siguiente manera:

```ruby
RSpec.describe ShoppingCart do
  describe "#total_price" do
    it "returns the sum of the prices of all products" do
      num_products = 2
      cart = ShoppingCart.new
      product = double(:product, price: 500)
      some_products = [product] * num_products

      expect_any_instance_of(ShoppingCart).to(
        receive(:products).and_return(some_products))

      expect(cart.total_price).to eq(num_products * product.price)
    end
  end
end
```

### `instance_double`

Para asegurarnos que los dobles se hagan sobre objetos existentes, podemos utilizar `instance_double` en lugar de símplemente `double`. Este, toma como primer argumento el nombre de una clase (que debe pertenecer al sistema) y verifica que los métodos llamados en las instancias de esta, realmente existan. Por ejemplo, si tenemos el siguiente test:

```ruby
RSpec.describe ShoppingCart do
  describe "#total_price" do
    it "returns the sum of the prices of all products" do
      num_products = 2
      cart = ShoppingCart.new
      # Observa que Product está mal escrito.
      product = instance_double("Prodruct", price: 500)
      some_products = [product] * num_products

      expect_any_instance_of(ShoppingCart).to(
        receive(:products).and_return(some_products))

      expect(cart.total_price).to eq(num_products * product.price)
    end
  end
end
```

Se producirá el siguiente error: `"Prodruct" is not a defined constant...`.

Si, por ejemplo, es el método `price` quien está mal escrito, se mostrará: `Product class does not implement the instance method: prices`

Recuerda, que para obtener esta funcionalidad, deberás tener en la configuración de RSpec el siguiente código:

```ruby
RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    # This option should be set when all dependencies are being loaded
    # before a spec run, as is the case in a typical spec helper. It will
    # cause any verifying double instantiation for a class that does not
    # exist to raise, protecting against incorrectly spelt names.
    mocks.verify_doubled_constant_names = true
  end
end
```

De otro modo, `instance_double` se comportará como un simple `double`.

Vale recordar aquí también que existe el método `class_double` que funciona como `instance_double`, pero asegura que los metodos llamados, se realicen sobre una clase en vez de una instancia.

### `spy`

Para explicar mejor este tema, voy a hacer una modificación a la clase `ShoppingCart`. En `initialize`, pasaré un objeto `Mailer` como parámetro.
Si al momento de calcular el `total_price` hay un mailer definido, se enviará un mail con el monto calculado. Además, harcodearé `products` para que devuelva un par de `Product`s y así simplificar las pruebas.

```ruby
class ShoppingCart
  attr_accessor :mailer

  def initialize(mailer)
    @mailer = mailer
  end

  def products
    [Product.new] * 2
  end

  def total_price
    total = products.inject(0) { |sum, product| sum + product.price }
    mailer.send_email(total) if mailer
    total
  end
end

class Mailer
  def send_email(amount)
    # ...
  end
end

class Product
  def price
    1000
  end
end
```

En el siguiente test, probaré que el método `send_mail` de `mailer` es llamado en `total_price`, usando `receive` como veníamos haciendo:

```ruby
RSpec.describe ShoppingCart do
  describe "#total_price" do
    it "returns the sum of the prices of all products" do
      # Arrange (Preparación)
      mailer = double(:mailer, send_email: true)
      cart = ShoppingCart.new(mailer)

      # Assert (Afirmación)
      expect(mailer).to receive(:send_email)

      # Assert (Afirmación)
      cart.total_price
    end
  end
end
```

¿No se ve un poco "antinatural" tener el código de afirmación antes que el de acción? En cualquier test "normal" (donde no se utilicen mocks), el orden sería:

1. **Arrange** (Preparación)
2. **Act** (Acción)
3. **Assert** (Afirmación)

o dicho de otra manera:

1. **Given**: Dado tal cosa...
2. **When**: Cuando ocurre tal otra...
3. **Then**: Se verifca que...

Ejemplo:

```ruby
class Robot
  def self.sum(a, b)
    a + b
  end
end

RSpec.describe Robot do
  describe "#sum" do
    it "returns valid sum" do
      # Arrange (Preparación)
      value1 = 4
      value2 = 6

      # Act (Acción)
      result = Robot.sum(value1, value2)

      # Assert (Afirmación)
      expect(result).to eq(10)
    end
  end
end
```

Para lograr esto con mocks, es que podemos utilizar `spy`. Así quedaría el ejemplo usando espías.

```ruby
RSpec.describe ShoppingCart do
  describe "#total_price" do
    it "returns the sum of the prices of all products" do
      # Arrange (Preparación)
      mailer = spy(:mailer)
      cart = ShoppingCart.new(mailer)

      # Act (Acción)
      cart.total_price

      # Assert (Afirmación)
      expect(mailer).to have_received(:send_email)
    end
  end
end
```

Como se puede apreciar, ahora nuestro test sigue la forma más natural:

1. **Given**: Dado tal cosa...
2. **When**: Cuando ocurre tal otra...
3. **Then**: Se verifca que...

Algo interesante de `spy`, es que puede ser reemplazado por `dobule` pero, mientras `spy` no exige que se definan los métodos que serán utilizados, `double` si lo hace. Este es el mismo ejemplo usando espías con `double`:

```ruby
RSpec.describe ShoppingCart do
  describe "#total_price" do
    it "returns the sum of the prices of all products" do
      # Arrange (Preparación)
      mailer = double(:mailer, send_mail: "ok")
      cart = ShoppingCart.new(mailer)

      # Act (Acción)
      cart.total_price

      # Assert (Afirmación)
      expect(mailer).to have_received(:send_email)
    end
  end
end
```
---

### Valores de retorno

Cuando hacemos un mock de un método, queremos reemplazar la implementación original por un valor falso que sirva a los propósitos del test. Para facilitarnos esto, RSpec viene con un conjunto de funciones. Las más comunes son:

#### `and_return`

Este método ya lo hemos estado utilizando en nuestros ejemplos anteriores. Se usa de esta manera:

```ruby
RSpec.describe Product do
  it do
    product = double(:product)
    allow(product).to receive(:price).and_return(500)
    expect(product.price).to eq(500)
  end
end
```

Es interesante destacar aquí que si se pasan varios valores como parámetro a `and_return`, en cada ejecución, se devolverá el siguiente de la lista. Por ejemplo:

```ruby
RSpec.describe Product do
  it do
    product = double(:product)
    allow(product).to receive(:price).and_return(500, 600)
    expect(product.price).to eq(500)
    expect(product.price).to eq(600)
  end
end
```

#### `and_raise`

Permite ejecutar una excepción como respuesta de un método. Por ejemplo:

```ruby
RSpec.describe Product do
  it do
    product = double(:product)
    allow(product).to receive(:price).and_raise("error")
    expect { product.price }.to raise_error("error")
  end
end
```

Este método admite alguna de las siguientes formas:

- `and_raise(ExceptionClass)`
- `and_raise("message")`
- `and_raise(ExceptionClass, "message")`
- `and_raise(instance_of_an_exception_class)`

Se recomienda siempre proveer la mayor cantidad de información. Es decir, se sugiere usar: `and_raise(ExceptionClass, "message")`

#### `and_call_original`

Algunas veces, sólo queremos probar que un método es llamado pero no queremos intervenir su valor de retorno. En estos casos, podemos utilizar `and_call_original` de la siguiente manera:

```ruby
class Product
  def price
    1234
  end
end

RSpec.describe Product do
  it do
    expect_any_instance_of(Product).to receive(:price).and_call_original
    expect(Product.new.price).to eq(1234)
  end
end
```

Aquí podemos ver que el uso de doubles no está permitido ya qué, al reemplazar el objeto por uno falso, se pierde la definición original de los métodos a los que accede. Entonces, para usar `and_call_original` hemos tenido que recurrir al uso de **partial double**. Esta técnica nos permite hacer mocks de métodos pero **en el objeto real**, preservando así la definición original de sus métodos. En este caso hemos hecho mock de `price` en "el verdadero" `Product`. Esto nos permitió verificar que el método se llamara correctamente sin alterar su funcionamiento.

---

### Restricciones

#### Cantidad de veces

A veces, es útil saber no sólo que un método fue llamado sino la cantidad de veces que lo fué. Para esto podemos usar: `.exactly(n).times`

```ruby
RSpec.describe ShoppingCart do
  describe "#total_price" do
    it "gets prices form products" do
      products_count = 10
      product = double(:product, price: 500)
      some_products = [product] * products_count
      cart = ShoppingCart.new(some_products)

      expect(product).to receive(:price).and_return(500).exactly(10).times

      cart.total_price
    end
  end
end
```

Hacer esto, nos garantiza que `price` fue llamado las 10 veces (`products_count`) que necesitamos que se llamara.
Similar a `exactly`, existen otros métodos:

- `once`: garantiza que el método se llame sólo una vez.
- `twice`: garantiza que el método se llame exactamente dos veces. Lo mismo que `.exactly(2).times`
- `at_least(:once)`: garantiza que el método se llame al menos una vez.
- `at_least(:twice)`: garantiza que el método se llame al menos dos veces.
- `at_least(n).times`: garantiza que el método se llame al menos n veces.
- `at_most(:once)`: garantiza que el método se llame como mucho una vez.
- `at_most(:twice)`: garantiza que el método se llame como mucho dos veces.
- `at_most(n).times`: garantiza que el método se llame como mucho n veces.

#### Argumentos

Así como podemos asegurar que los métodos sean llamados una cierta cantidad de veces, también podemos asegurar que se llamen con ciertos parámetros usando `with`. Volviendo con la clase `Robot`:

Ejemplo:

```ruby
class Robot
  def self.sum(a, b)
    a + b
  end
end
```

Si queremos asegurar que `sum` se llame con los valores correctos, podemos escribir el test de la siguiente manera:

```ruby
RSpec.describe Robot do
  describe "#sum" do
    it "calculates sum with correct params" do
      value1 = 4
      value2 = 6

      expect(Robot).to receive(:sum).with(value1, value2)

      Robot.sum(value1, value2)
    end
  end
end
```

Armando el test de esta manera, si pasamos un valor incorrecto en `with`, así:

```ruby
RSpec.describe Robot do
  describe "#sum" do
    it "calculates sum with correct params" do
      value1 = 4
      value2 = 6

      expect(Robot).to receive(:sum).with("wrong", "values")

      Robot.sum(value1, value2)
    end
  end
end
```

Luego de correr el test, veremos el siguiente error: `received :sum with unexpected arguments...`.

Además, `with` permite otras expresiones:

- `with(/bar/)`: que hace match con `foo("barn")` o `foo("bart")`.
- `with(any_args)`: que admite como su nombre lo dice cualquier cantidad de parámetros.
- `with(no_args)`: asegura que el método sea llamado sin parámetros.
- `with(hash_including(:a => 1))`: asegura que el método sea llamado con un hash contentiendo `{:a => 1}`.
- `with(kind_of(Numeric))`: asegura que el método sea llamado con un objeto de tipo `Numeric`.

Hay otros más, pero estos son de los más utilizados.

---

### Sintaxis obsoleta (deprecated)

Existen diferencias en la sintaxis introducidas en el salto de RSpec 2 a RSpec 3. A continuación voy a mostrar cuales son para evitar confusiones. Sobre todo cuando uno googlea o visita stackoverflow en busca de guía en el tema de mocks.

```ruby
describe 'new RSpec mocks and expectations syntax' do
  let(:obj) do
    # new                          # deprecated
    double('foo')                  # obj = mock('foo')
  end

  it "uses the new allow syntax for mocks" do
    # new                          # deprecated
    allow(obj).to receive(:bar)    # obj.stub(:bar)
  end

  it "uses the new expect syntax for expectations" do
    # new                          # deprecated
    expect(obj).to receive(:baz)   # obj.should_receive(:baz)
    obj.baz
  end
end
```

En la configuración de RSpec se puede especificar que se habilite la sintaxis antigua, pero se recomienda no hacerlo.

```ruby
RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.syntax = :should # :expect es el valor por defecto.
  end
end
```

Bueno, esto ha sido todo! Espero esta guía les sirva en el futuro para hacer más felices sus vidas cuando escriban mocks :)

---

### Casi "Fe de erratas" :P

Cuando empecé a investigar sobre Mocks, inmediatamente empezaron a aparecer conceptos como: double, fake, stubs, etc. A lo largo del post, me referí a todos estos conceptos, usando simplemente la palabra **Mock**. Muchos, debido a esta grosera generalización pueden haber dejado de leer el post! pero, si llegaron a leer hasta aquí, sepan que lo hice apoyado en la explicación que aparece en el **Capítulo 3: "Taking Control of State with Doubles and Hooks"** de [RSpec Essentials](http://shop.oreilly.com/product/9781784395902.do):

*The word mock is generic. Often the words stub, fake, and double are used to mean the same thing. To be precise, we could make a distinction between mocks and stubs. A mock is a fake object that stands in the place of an actual object. A stub is a fake method that is executed in place of an actual method. In practice, the terms are used interchangeably*

La motivación de usar sólo la palabra mock, fue para restar "complejidad filosófica" al tema, concentrándome más en la práctica con RSpec. Creo que la diferencia entre estos conceptos, merece un post aparte...

---

### Fuentes

- [RSpec Essentials by Mani Tadayon](http://shop.oreilly.com/product/9781784395902.do)
- [StackOverflow: Diferencia entre Mock y Stub](http://stackoverflow.com/questions/3459287/whats-the-difference-between-a-mock-stub)
- [RSpec Mocks 3.5](https://relishapp.com/rspec/rspec-mocks/v/3-5/docs)
- [Stubs, Mocks and Spies in RSpec by Simon Coffey ](https://about.futurelearn.com/blog/stubs-mocks-spies-rspec)
- [Mocks Aren't Stubs by Martin Fowler](http://martinfowler.com/articles/mocksArentStubs.html)
- [Wikipedia: Mock Object](https://en.wikipedia.org/wiki/Mock_object)
