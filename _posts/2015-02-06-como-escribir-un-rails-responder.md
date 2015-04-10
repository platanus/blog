---
title: "Cómo escribir un Rails Responder"
layout: post
author: juliogarciag
categories:
    - rails
    - api
    - good-practices
---

Hace unos días Rails fue actualizado a 4.2 trayendo consigo varias mejoras de performance y otras cosas bastante interesantes como [AdequateRecord](http://tenderlovemaking.com/2014/02/19/adequaterecord-pro-like-activerecord.html), así que intenté actualizar una api Rails 4.1 a 4.2 y me encontré con algunas cosas interesantes:

1. [ActiveModelSerializers](https://github.com/rails-api/active_model_serializers), que sobreescribía la funcionalidad del método `render` de los controladores dejó de funcionar.
2. `ApplicationController#respond_with` y `ApplicationController.respond_to` habían desaparecido de la faz de Rails y su funcionalidad había sido extraída en una gema llamada [responders](https://github.com/plataformatec/responders).

Ante esto me vi en la necesidad de recuperar de algún modo la funcionalidad perdida y arreglar el proyecto en 4.2 o mantenerme en 4.1 hasta que ActiveModelSerializers funcione bien. Decidí que seguiría intentando actualizr hasta que fuese realmente imposible actualizar o para hacerlo tuviese que volver inmantenible todo. Debía arreglar los serializers a ver qué pasaba.

Previamente, si uno tenía un serializer así:

```ruby
class ProductSerializer < ActiveModel::Serializer
  attributes :id, :name, :kind
end
```

bastaba con esto:

```ruby
class Api::ProductController < Api::BaseController
  def show
    respond_with find_product
  end

  # ...
end
```

para tener una respuesta así:

```json
{ "id": 1, "name": "Github T-Shirt", "kind": "t-shirt" }
```

en vez de algo así:

```json
{ "id": 1, "name": "Github T-Shirt", "kind": "t-shirt", "created_at": "...", "updated_at": "...", "other_attribute": "..." }
```

Bueno, esto ya no funcionaba al actualizar Rails. La razón era que ActiveModelSerializers basaba su principal forma de uso en la implementación de `render` y como la implementación de `render` no es parte de la API pública de Rails (como sí lo es la signatura del método), todo se rompió. (Nota: No basarse en detalles de implementación para escribir una librería porque nadie te puede garantizar que ese detalle siga funcionando en el futuro) Un uso más sano y menos mágico de los serializers es éste:

```ruby
def show
  respond_with ProductSerializer.new(find_product).as_json
end
```

Aunque la verdad es que esta última implementación hubiese fallado también porque `respond_with` trabaja con modelos de Rails, no con un hash. Antes todo funcionaba porque `respond_with` llamaba a `render` y `render` llamaba al serializer. Ahora simplemente no funcionaba usarlo de este modo y había que hacer algo así:

```ruby
def show
  render :json => { ProductSerializer.new(find_product).as_json }, :status => :ok
end
```

Lo que en verdad no es muy limpio y deja algunos detalles de implementación en el aire. Dejar de usar `respond_with` aquí parecía la *dirty quick fix* del día. Sin embargo, los casos en que `respond_with` es realmente útil no son los casos en que sólo se muestra un objeto. Por ejemplo, en un `create` hubiese tenido que pasar de esto:

```ruby
def create
  respond_with Product.create(creation_params)
end
```

a algo así:

```ruby
def create
  product = Product.create(creation_params)
  render :json => ProductSerializer.new(product).as_json, :status => :created
end
```

Hay demasiados detalles de implementación sorteando por todos lados (status, json, serializer, etc) y hubiese tenido que refactorizar todos los controladores de la API **¡para agregar más código!**. Bueno, como que no es una muy buena práctica, así que decidí hacer algo que ya había hecho antes pero en menor medida: un responder personalizado.

## Responders al Rescate

El método `respond_with` parece mágico o por lo menos se comporta como tal la primera vez que lo vemos. Es un método que hace que un recurso se serialize a json, devuelva el código preciso para el método http que estamos usando, setee flashes en respuestas html, haga caching, todo en un sólo lugar. Bueno, la verdad es que internamente muy mágico no es. Parafraseando su implementación dentro de un controlador, su comportamiento es algo así:

```ruby
self.responder = ApiResponder

def respond_with(resource, options = {})
  responder.new(self, [resource].flatten, options).respond
end
```

Lo que significa que en realidad un responder no es más que una clase que decide cómo vamos a mostrar un recurso. Es una buena abstracción porque permite tratar con los modelos como recursos aislados y hacer algo muy interesante: Aplicar funcionalidad común a todos nuestros endpoints. Además, y más importante aún, es un buen lugar para, programáticamente, especificar convenciones con respecto a cómo debería ser la API.

Antes de explicar lo último, que es en realidad el punto de este post, primero voy a explicar cómo es que esta pequeña abstracción (Responders) permitió recuperar la funcionalidad de ActiveModelSerializers sin necesidad de alterar todos y cada uno de los controladores.

Primero que nada hubo que agregar la gema responders al `Gemfile` para recuperar `respond_with`.

```ruby
gem 'responders', '~> 2.0'
```

Luego hay que crear el responder medio vacío preferentemente en `app/responders` porque, como todo dentro del directorio `app`, es recargado por Rails:

```ruby
class ApiResponder < ActionController::Responder
  
end
```

y finalmente inyectar la clase en el controlador:

```ruby
class Api::V1::BaseController < ActionController::Base
  self.responder = ApiResponder
  respond_to :json
end
```

Esto es sólo para registrar nuestro responder. Implementemos el método `respond` dentro de `ApiResponder` para ver qué es lo que podemos hacer. El siguiente snippet contiene bastantes comentarios de qué es lo que hace esta implementación así que sería bueno mirarlos también :)

```ruby
# Aquí tenemos acceso a algunos métodos útiles como `head`, `delete?`, `post?`,
# `patch?`, `get?` así como a algunos objetos importantes como el recurso en
# el método `resource` y el controlador con el método `controller`.
# Además tenemos un hash de opciones que es el segundo parámetro de
# `respond_with`.
def respond
  # 1. Si es delete, sólo retornemos la cabecera sin contenido (:no_content
  # es un símbolo que en realidad significa 204 NO CONTENT, `head` provoca
  # que no haya contenido.
  return head :no_content if delete?

  # 2. Busquemos el serializer para este recurso
  # Generamos el serializer. Esto es cosa de la api de ActiveModelSerializers.
  # pero la idea es más o menos generar un serializer y en caso no haya uno
  # usar al recurso mismo como si fuera el serializer
  serializer = ActiveModel::Serializer.serializer_for(resource).try(:new, resource, options) || resource

  # 3. Finalmente usamos render, pero antes debemos definir cuál es 
  # el código de estado de la respuesta. La idea es que solamente
  # la creación retorne 201 CREATED. El resto de sucesos (update, show, index)
  # deben retornar simplemente 200 OK.
  status_code = post? ? :created : :ok

  controller.render options.merge({
    # Usando el método `as_json` del serializer. Éste es un ejemplo del uso
    # del duck typing. Un serializer y un recurso tienen `as_json` así
    # que ambos funcionan aquí. Si no tenemos un serializer atado a un 
    # recurso, seguiremos teniendo un buen fallback.
    :json => serializer.as_json,
    :status => status_code
  })
end
```

Una vez que probamos de nuevo todo, nuestros viejos y caídos `respond_with`, funcionarán correctamente. En este caso hemos usado un responder para dejar en claro algunas convenciones sobre nuestra API:

1. Que cuando un DELETE funciona, se retorna 204 y no se retorna un cuerpo.
2. Que cuando un POST funciona, se retorna 201.
3. Que cuando un GET, un PATCH o un PUT funciona, se retorna 200.
4. Que en caso se utilice un recurso para responder y no se esté buscando eliminar el objeto, se usará un serializer para mostrar el recurso.
5. Que en caso de que no se especifique un serializer, se usará al recurso mismo porque ambos tienen un método `as_json` que retorna un hash que puede serializarse a json.

El hecho de tener varias convenciones de nuestra API enforzadas por código y no sólo por documentación o disciplina disminuye los riesgos de perder la sincronización entre ciertas buenas prácticas y el código realizado. No hay riesgo de olvidar instanciar el serializer en todos lados, de confundir el código de la respuesta o de devolver un 204 con contenido.

## Casi Conclusión: Manejo de Errores

Bueno, ahora que tenemos un responder, lo usaremos para hacer algo medio divertido: Mostrar errores cada vez que ocurre un error en algo que respondemos. De esta forma nos olvidamos del horrible `if` en cada acción del controlador cada vez que queremos mostrar errores. Será como si mostrar errores fuese gratis. Veamos cómo lo haríamos:

Primero, movemos la lógica para mostrar un recurso de donde está porque nuestro método es muy grande. Además, moveremos la obtención del código de estado también:


```ruby
def respond
  return head :no_content if delete?

  display resource, :status_code => status_code
end

private

def display(resource, given_options = {})
  controller.render options.merge(given_options).merge({
    :json => serializer.as_json
  })
end

def serializer
  serializer_class = ActiveModel::Serializer.serializer_for(resource)
  serializer_class.try(:new, resource, options) || resource
end

def status_code
  return :created if post?
  return :ok
end
```

Ahora que el código está más limpio agreguemos algo extra en la lógica del manejo de la respuesta.

```ruby
def respond
  return display_errors if has_errors?
  # ...
end

private

def display_errors

end
```

`has_errors?` es un método heredado desde `ActionController::Responder` que  revisa si hay errores en el recurso. Como la única forma en que un recurso puede tener errores es luego de una validación, esto puede ocurrir luego de un fallido `create` o un fallido `update`, así que es el típico caso en que guardamos un recurso y queremos devolverlo. La idea es que no se tenga que hacer esto:

```ruby
def create
  person = Person.create(creation_params)
  if person.valid?
    respond_with person
  else
    render :status => :unprocessable_entity, :json => resource.errors.as_json
  end
end
```

Y en su lugar sólo baste con esto:

```ruby
def create
  respond_with Person.create(creation_params)
end
```

Además, colocando la validación en el serializer, podemos definir el modo en que queremos que los errores sean mostrados en la API. Esto puede variar según ciertas necesidades como el uso o no de I18n, dónde se quieran traducir la información de los errores y cuál es el formato en que se quieran mostrar los errores. Por ejemplo, la siguiente implementación de `display_errors` es bastante genérica pero cumple con su cometido:

```ruby
def display_errors
  controller.render({
    :status => :unprocessable_entity,
    :json => { errors: format_errors }
  })
end

def format_errors
  resource.errors.as_json
end
```

Uno podría cambiar la implementación por algo más acorde a las necesidades del frontend y de las necesidades de internacionalización si así fuera el caso.

## Conclusión

Usar Responders trae no sólo una ventaja a nivel de cantidad de código a escribir sino que es un lugar para colocar abstracciones genéricas sobre todos los recursos de la API y obligar a que se sigan ciertas convenciones y buenas prácticas casi sin siquiera saberlo.

Finalmente, aquí dejo el ejemplo completo del Responder y su uso en un controlador:

### Responder

Localizado en `app/responders/api_responder.rb`:

```ruby
class ApiResponder < ActionController::Responder
  def respond
    return display_errors if has_errors?
    return head :no_content if delete?
  
    display resource, :status_code => status_code
  end
  
  private
  
  def display(resource, given_options = {})
    controller.render options.merge(given_options).merge({
      :json => serializer.as_json
    })
  end
  
  def serializer
    serializer_class = ActiveModel::Serializer.serializer_for(resource)
    if serializer_class.present?
      serializer_class.new(resource, options)
    else
      resource
    end
  end
  
  def status_code
    return :created if post?
    return :ok
  end
  
  def display_errors
    controller.render({
      :status => :unprocessable_entity,
      :json => { errors: format_errors }
    })
  end
  
  def format_errors
    resource.errors.as_json
  end
end
```

### Base Controller

Localizado en `app/controllers/api/v1/base_controller.rb`:

```ruby
class Api::V1::BaseController < ApplicationController
  self.responder = ApiResponder
  respond_to :json
end
```

### Products Controller

Localizado en `app/controllers/api/v1/products_controller.rb`:

```ruby
class Api::V1::ProductsController < Api::V1::BaseController
  # GET => 200 OK -> [ { ... }]
  def index
    respond_with Product.all
  end
  
  # POST { name: 'Product' } => 201 CREATED -> { id: 1, name: 'Product', state: 'created' } 
  # POST { } => 422 UNPROCESSABLE ENTITY -> { errors: { name: ["can't be blank"] } }
  def create
    respond_with Product.create(creation_params)
  end

  # GET :id => 200 OK -> { id: 1, name: 'Product' }
  def show
    respond_with found_product
  end

  # PATCH { name: 'New Product', state: 'published' } => 200 OK -> { id: 1, name: 'New Product', state: 'published' }
  # PATCH {} => 200 OK -> { id: 1, name: 'New Product', state: 'published' }
  # PATCH { name: '' } => 422 UNPROCESSABLE ENTITY -> { errors: { name: ["can't be blank"] } } 
  def update
    found_product.update(update_params)
    respond_with found_product
  end
  
  # DELETE :id => 204 NO CONTENT
  def destroy
    found_product.destroy
    respond_with found_product
  end
  
  private
  
  def creation_params
    params.permit(:name)
  end
  
  def update_params
    params.permit(:name, :state)
  end
  
  def found_product
    @found_product ||= Product.find(params[:id])
  end
end
```
