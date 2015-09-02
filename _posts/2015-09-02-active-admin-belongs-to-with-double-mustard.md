---
layout: post
title: Active Admin BelongsTo con doble mostaza
author: bunzli
tags:
  - rails
  - active admin
---

Voy a mostrarles una forma alternativa de presentar un modelo relacionado con otro modelo a través de **belongs_to** en Active Admin.

Tenemos dos modelos

- `Institution`: representa instituciones bancarias (bancos)
- `Product`: representa los productos que cada institución ofrece (Ej: cuenta corriente)

Un Institution `has_many` Products.

Lo más básico para active admin sería ofrecer dos menús para administrar estos dos recursos por separado. Pero, no nos gusta porque no es tan intuitivo o porque nos queremos ahorrar un menú.

Usemos la propiedad [belongs_to](https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#belongs-to) de active admin!. Pero el uso convencional, tampoco nos convence 100% para este caso. Lo que en realidad queremos es juntar la institución con sus productos conceptualmente en la mente del usuario.

El resultado de este "aproach" tiene dos vistas principales

## La lista de instituciones

Queremos mostrarla de la manera más simple posible

![institution-list](/images/active-admin-belongs-to/institution-list.png)

## La vista de una institución es la lista de productos

Es quizás la vista más importante. Lo que se busca resaltar es que lo más importante de una institución son sus productos

![institution-list](/images/active-admin-belongs-to/product-list.png)

## Paso a Paso para lograr la doble mostaza

#### 1. La lista de instituciones

No es necesario tener el filtro ni las acciones masivas

```ruby
# admin/institution.rb
config.batch_actions = false
config.filters = false
```

Una sola acción por institución

```ruby
# admin/institution.rb
index do
  ...
  actions defaults: false do |institution|
    link_to "View", admin_institution_path(institution)
  end
end
```

#### 2. Al entrar a una institución, vemos la lista de productos

Tenemos que redireccionar la vista show de una institution al index de sus products

```ruby
# admin/institution.rb
controller do
  def show
    redirect_to admin_institution_products_path(resource)
  end
end
```

Algunas configuraciones en el admin de product para sacar el filtro y acciones en masa. Además al usar la propiedad belongs_to, queremos que no se modifique el menú

```ruby
# admin/product.rb
belongs_to :institution
menu false
navigation_menu :default
config.batch_actions = false
config.filters = false
```

#### 3. Mostremos la información de la institución en el lado derecho

```ruby
# admin/product.rb
sidebar "Institution Details", only: :index do
  attributes_table_for institution do
    row :id
    row :name
    row :namespace
    row :created_at
    row :updated_at
  end
end
```

```scss
// assets/active_admin.css.scss
.sidebar_section .attributes_table th {
  width: 90px;
}
```

#### 4. Agreguemos las acciones editar y eliminar la institución acá

```ruby
# admin/product.rb
action_item only: :index do
  link_to "Edit #{institution.name}", edit_admin_institution_path(institution)
end

action_item only: :index do
  link_to "Delete #{institution.name}",
    admin_institution_path(institution),
    method: :delete,
    "data-confirm"  => "Are you sure?"
end
```

Sí!, el delete con confirmación :)

#### 5. No queremos tener una vista especial de cada producto. Sólo queremos editar y eliminar.

Cada vez que se edite un producto, o se cree uno nuevo, lo normal es que se redireccione a la vista de ese recurso. Nosotros lo redireccionaremos al index de productos. El mensaje de la acción anterior se mantendrá! y es suficiente feedback.

```ruby
# admin/product.rb
controller do
  def show
    redirect_to edit_admin_institution_product_path(resource.institution, resource)
  end
end
```

En la lista, solo ofrecemos editar

```ruby
# admin/product.rb
index do
...
  actions(defaults: false) do |product|
    link_to "Edit", edit_admin_institution_product_path(product.institution, product)
  end
...
end
```

Al editar, ofrecemos el botón de eliminar

```ruby
# admin/product.rb
action_item only: :edit do
  link_to "Delete #{product.name}",
    admin_institution_product_path(product.institution, product),
    method: :delete,
    "data-confirm"  => "Are you sure?"
end
```

#### 6. Cambiemos el título para aparezca el nombre de la institución

Este es un detalle, pero es dificil encontrar en Google como se hace

```ruby
# admin/product.rb
index title: -> { "Products in #{parent.name}" } do
...
end
```

Con un poco de movimiento se puede jugar con activeadmin para hacer algunas vistas más adecuadas.
