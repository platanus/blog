---
layout: post
title: Integrar cocoon gem con Active Admin
author: ldlsegovia
tags:
    - rails
    - active admin
    - cocoon
---

Hay veces que el método `form`, que viene en el DSL de Active Admin, no nos alcanza. En estos casos, recurrimos al uso de partials para generar nuestras custom views. El hacer esto, nos dá la flexibilidad que buscabamos, pero a la vez, perdemos todos aquellos métodos que nos proporciona el DSL. Uno de los que perdemos (y extrañamos) es: `has_many`. Este método, permite manejar nested resources de manera no dolorosa.
Para recuperar esta funcionalidad perdida en custom views, es que propongo el uso de la gema [Cocoon](https://github.com/nathanvda/cocoon).
A continuación, les mostraré una forma de integrarla con Active Admin...

Supongamos que tenemos dos modelos:

```ruby
# == Schema Information
#
# Table name: properties
#
#  id             :integer          not null, primary key
#  name           :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class Property < ActiveRecord::Base
  has_many :options, dependent: :destroy
  accepts_nested_attributes_for :options, reject_if: :all_blank, allow_destroy: true
end
```

```ruby
# == Schema Information
#
# Table name: options
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  property_id :integer
#

class Option < ActiveRecord::Base
  belongs_to :property
end
```

Ahora supongamos que queremos, en el formulario `Property` de Active Admin, agregar `many` `Option`s. Para resolver esto usando Cocoon, podemos seguir los siguientes pasos:

* Asegurarnos de que la relación está bien armada entre los modelos. Es decir, el modelo `Property`, debe tener `has_many :options` y `accepts_nested_attributes_for :options` y `Option`, debe tener `belongs_to :property`.

* Crear el `partial` para el formulario de `Property` en: *your-app/app/views/admin/property/_form.html.erb* con el siguiente contenido:

```erb
<%= semantic_form_for [:admin, resource] do |f| %>
  <%= f.semantic_errors %>

  <%= f.inputs name: "Propiedad" do %>
    <%= f.input :name %>
  <% end %>

  <%= f.inputs name: "Opciones" do %>
    <li class="has_many_container">
      <%= f.semantic_fields_for :options do |option| %>
        <%= render 'option_fields', f: option %>
      <% end %>
      <%= link_to_add_association 'Agregar Opción', f, :options, class: "button has_many_add" %>
    </li>
  <% end %>

  <%= f.actions %>
<% end %>
```
> Es importante aquí, que el botón "Agregar" (`link_to_add_association`), este dentro del mismo contenedor (`has_many_container`) que los items (`<%= render 'option_fields'...`)

* Crear el partial para el formulario de `Option` en *your-app/app/views/admin/property/_option_fields.html.erb* con el siguiente contenido:

```erb
<%= f.inputs class: "inputs nested-fields has_many_fields" do %>
  <%= f.input :name %>
  <li>
    <%= link_to_remove_association "Eliminar", f %>
  </li>
<% end %>
```
> Es particularmente importante aquí la inclusión de la clase `nested-fields`, ya que es la que usa cocoon para identificar a un item específico.

* Crear en Active Admin, el recurso `Property` (*/your-app/app/admin/property.rb*) de la siguiente manera:

```ruby
ActiveAdmin.register Property do
  form partial: 'form'

  permit_params :name, options_attributes: [:id, :name, :_destroy]
end
```
> No olvidar agregar `options_attributes` al `permit_params`.

* Modificar opciones de Cocoon agregando en *your-app/app/assets/javascripts/active_admin.js* el siguiente código:

```javascript
$(document).ready(function() {
  $("a.add_fields").
    data("association-insertion-position", 'before').
    data("association-insertion-node", 'this');
});
```

> Lo único que estamos diciendo con el código anterior, es que queremos que los nuevos items (opciones en nuestro ejemplo) se añadan sobre el botón "Agregar Opción".

* Modificar algunos estilos para hacer encajar Active Admin con Cocoon.
*your-app/app/assets/stylesheets/active_admin.css.scss*

```sass
.nested-fields fieldset {
  padding-top: 0 !important;
}

li.has_many_container {
  padding-top: 0px !important;
  padding-bottom: 0px !important;
}
```

Sí todo salió bien, deberían ver algo así:

![cocoon-form-example](/images/cocoon-form-example.png)

Enjoy!
