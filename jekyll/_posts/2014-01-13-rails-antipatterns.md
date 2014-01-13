---
title: Rails Antipatterns
author: Leandro Segovia
layout: post/leandro-segovia
categories:
    - rails
    - design patterns
---

Hace un tiempo leí el libro **[Rails AntiPatterns: Best Practice Ruby on Rails Refactoring][1]** de los autores `Chad Pytel` y `Tammer Saleh`. Este libro intenta dar solución a muchas malas prácticas en las que normalmente incurrimos a la hora de diseñar y estructurar nuestro código Rails. Cada una de estas malas practicas es, en el libro, un AntiPattern y por cada anti-patrón los autores presentan una o varias soluciones. Si bien el libro tiene sus años, me parece que su contenido es completamente vigente a la fecha y con esto en mente escribo este post con el objeto de mostrar brevemente aquellas secciones (antipattern/solución) del mismo que me han parecido más útiles a lo largo de mi camino aprendiendo Rails.

## AntiPattern 1: Modelos gordos

Ocurre cuando nuestra aplicación va creciendo y nos encontramos ubicando método tras método dentro de un úncio modelo.

```ruby
# app/models/order.rb
class Order < ActiveRecord::Base

  def self.find_purchased
    # ...
  end

  def self.find_waiting_for_review
    # ...
  end

  def self.find_waiting_for_sign_off
    # ...
  end

  def self.find_waiting_for_sign_off
    # ...
  end

  def self.advanced_search(fields, options = {})
    # ...
  end

  def self.simple_search(terms)
    # ...
  end

  def to_xml
    # ...
  end

  def to_json
    # ...
  end

  def to_csv
    # ...
  end

  def to_pdf
    # ...
  end

end
```

## Solución

Dividir código del modelo en módulos por funcionalidad.

```ruby
# app/models/order.rb
class Order < ActiveRecord::Base
  extend OrderStateFinders
  extend OrderSearchers
  include OrderExporters
end

# lib/order_state_finders.rb
module OrderStateFinders

  def find_purchased
    # ...
  end

  def find_waiting_for_review
    # ...
  end

  def find_waiting_for_sign_off
    # ...
  end

  def find_waiting_for_sign_off
    # ...
  end

end

# lib/order_searchers.rb
module OrderSearchers

  def advanced_search(fields, options = {})
    # ...
  end

  def simple_search(terms)
    # ...
  end

end

# lib/order_exporters.rb
module OrderExporters

  def to_xml
    # ...
  end

  def to_json
    # ...
  end

  def to_csv
    # ...
  end

  def to_pdf
    # ...
  end

end
```

## AntiPattern 2: Código duplicado entre modelos

Una de las posibilidades de que ocurra es cuando tenemos que agregar una misma funcionalidad a dos modelos distintos. Por ej: tengo los modelos **Event** y **TicketType** y en ambos debo manejar estados. El problema aquí es que necesitaré el mismo código en ambos modelos.

## Solución

Utilizar módulos para sacar esa lógica repetida y luego incluir ese módulo en ambos modelos. Siguiendo el ejemplo...

```ruby
module PTE
  module RowStatus
    ROW_ACTIVE = 1
    ROW_DELETED = 0

    def self.included(base)
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      base.before_save :check_status_validity
      base.before_create :check_status_validity
    end

    module ClassMethods
      def row_statuses
        [ROW_ACTIVE, ROW_DELETED]
      end

      def active
        self.where(status: ROW_ACTIVE)
      end

      def deleted
        self.where(status: ROW_DELETED)
      end
    end

    module InstanceMethods
      def check_status_validity
        if !self.is_row_status_valid?
          raise PTE::Exceptions::RowStatusError.new(
            "Status must be one of these: #{self.class.row_statuses.join(', ')}")
        end
      end

      def is_row_status_valid?
        self.class.row_statuses.include? self.status
      end
    end
  end
end

class Event < ActiveRecord::Base
  include PTE::RowStatus
  # lots of code
end

class TicketType < ActiveRecord::Base
  include PTE::RowStatus
  # lots of code
end
```

Luego puedo hacer algo como:

```ruby
Event.deleted
TicketType.deleted
```

## AntiPattern 3: PHPitis

Se da normalmente en developers que están acostumbrados a trabajar con lenguajes como php donde no es extraño ver lógica de negocios y hasta código SQL en las vistas. Hacer esto en Rails que utiliza el patrón MVC es un error. Por ej:

```ruby
<% if current_user &&
      (current_user == @post.user ||
      @post.editors.include?(current_user)) &&
      @post.editable? &&
      @post.user.active? %>

  <div class="feed">
    <% if @project %>
      <%= link_to "Subscribe to #{@project.name} alerts.",
        project_alerts_url(@project, :format => :rss),
        :class => "feed_link" %>

    <% else %>
      <%= link_to "Subscribe to these alerts.",
        alerts_url(format => :rss),
        :class => "feed_link" %>
    <% end %>
  </div>
<% end %>
```

## Solución

En el ejemplo anterior se ven dos problemas:

Primero: hay lógica de presentación que se puede encapsular en un helper.

```ruby
def rss_link(project = nil)
  if project
    link_to "Subscribe to #{project.name} alerts.",
    project_alerts_url(project, :format => :rss),
    :class => "feed_link"
  else
    link_to "Subscribe to these alerts.",
    alerts_url(:format => :rss),
    :class => "feed_link"
  end
end
```

Segundo: hay lógica de dominio en la vista. Esto se puede corregir moviéndola a modelos.

```ruby
<% if @post.editable_by?(current_user) %>
  <%= rss_link(@project) %>
<% end %>
```

## AntiPattern 4: Modelos vouyeristas

Ocurre cuando abusamos de la potencialidad de Rails y nos olvidamos de la orientación a objetos.
Por ejemplo el siguiente código, que es común de ver, va en contra del encapsulamiento:

```ruby
<%= @invoice.customer.name %>
<%= @invoice.customer.address.street %>
<%= @invoice.customer.address.city %>
<%= @invoice.customer.address.state %>
<%= @invoice.customer.address.zip_code %>
```

## Soluciones

1. Seguir la **[Law of Demeter][2]**
2. Crear métodos de instancia para acceder a los recursos o usar **[delegate][3]**

```ruby
class Address < ActiveRecord::Base
  belongs_to :customer
end

class Customer < ActiveRecord::Base
  has_one :address
  has_many :invoices

  def street
    address.street
  end

  def city
    address.city
  end

  def state
    address.state
  end

  def zip_code
    address.zip_code
  end
end

class Invoice < ActiveRecord::Base
  belongs_to :customer

  def customer_name
    customer.name
  end

  def customer_street
    customer.street
  end

  def customer_city
    customer.city
  end

  def customer_state
    customer.state
  end

  def customer_zip_code
    customer.zip_code
  end
end
```

o más limpio con delegate

```ruby
class Address < ActiveRecord::Base
  belongs_to :customer
end

class Customer < ActiveRecord::Base
  has_one :address
  has_many :invoices
  delegate :street, :city, :state, :zip_code, :to => :address
end

class Invoice < ActiveRecord::Base
  belongs_to :customer
  delegate :name,
    :street,
    :city,
    :state,
    :zip_code,
    :to => :customer,
    :prefix => true
  end
```

y en la vista...

```ruby
<%= @invoice.customer_name %>
<%= @invoice.customer_street %>
<%= @invoice.customer_city %>,
<%= @invoice.customer_state %>
<%= @invoice.customer_zip_code %>
```

## AntiPattern 5: Inútiles tablas de Lookup

Por algún motivo (sólo Dios sabe), muchas veces decidimos crear modelos y tablas para almacenar estados e información que sólo es útil para el funcionamiento interno de una aplicación. La pregunta es: con que objeto se hace esto?

* Para permitir que un administrador agregue un nuevos estados por ej? creo que no. El 90% de las veces ese nuevo estado estará asociado a nueva lógica que el admin no podrá agregar.
* Será entonces para sentir que nuestros valiosos estados no descansan en poco controlables Strings? puede ser! Quizás uno de los motivos por los que agregamos una tabla es para poder tener algo como esto:

```ruby
class Model < ActiveRecord::Base
  belongs_to :status

  def self.deleted_status
    Status.find_by_name :deleted
  end
end
```

y luego preguntar por esto:

```ruby
if @obj.status == Model.deleted_status
  #do something
end
```

Quizás el temor está en que ocurra algo así:

```ruby
if @obj.status == :deletd # Escribir "deletd" cuando lo que se en realidad se quiso escribir es "deleted"
  #do something
end
```

## Solución

Con metaprogramming podemos generar métodos dinámicos, seguros (si están bien testeados) de está manera y escribiendo muy poco código:

```ruby
class Model < ActiveRecord::Base
  STATUSES = [:completed, :deleted]

  STATUSES.each do |status_name|
    self.class.class_eval do
      define_method("#{status_name}_status") do
        status_name.to_s
      end
    end
  end
end
```

Con esto, podemos tener métodos lograr esto:

```ruby
if @obj.status == Model.deleted_status
  #do something
end
```

sin necesidad de nuevos modelos, tablas, migraciones ni admins!

## AntiPattern 6: Controllers de muchas caras

El típico caso es el de la sesión conviviendo con los usuarios.

```ruby
class UsersController < ApplicationController

  def login
    if request.post?
      if session[:user_id] = User.authenticate(params[:user][:login],
        params[:user][:password])
        flash[:message] = "Login successful"
        redirect_to root_url
      else
        flash[:warning] = "Login unsuccessful"
      end
    end
  end

  def logout
    session[:user_id] = nil
    flash[:message] = 'Logged out'
    redirect_to :action => 'login'
  end

  # RESTful actions
end
```

## Solución

Identificar el recurso y sacar el resto en otro controller.

```ruby
class UsersController < ApplicationController
  # RESTful actions
end

class SessionsController < ApplicationController

  def login
    if request.post?
      if session[:user_id] = User.authenticate(params[:user][:login],
        params[:user][:password])
        flash[:message] = "Login successful"
        redirect_to root_url
      else
        flash[:warning] = "Login unsuccessful"
      end
    end
  end

  def logout
    session[:user_id] = nil
    flash[:message] = 'Logged out'
    redirect_to :action => 'login'
  end
end
```

## AntiPattern 7: Errores inaudibles

Ocurre cuando intentamos evitar una "explosión" ocultando información importante para corregir el problema subyacente.

```ruby
Event.create! rescue nil
=> nil
```

Si el código anterior tiene validaciones la excepción `ActiveRecord::RecordInvalid` quedará oculta por `nil` evitando que identifiquemos por qué no se creó el evento.

## Solución

No usar rescue nil y capturar las excepciones posibles.

[1]: http://railsantipatterns.com/
[2]: http://es.wikipedia.org/wiki/Ley_de_Demeter
[3]: http://rdoc.info/docs/rails/Module:delegate

