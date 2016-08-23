---
layout: post
title: Mejorando nuestra vida con ActiveAdmin Addons
author: gmq
tags:
  - rails
  - active admin
excerpt_separator: <!--more-->

---
ActiveAdmin es una herramienta espectacular: Defines modelos, corres un par de migraciones y listo, tienes un panel de administración. Pero por defecto es algo espartano, en general entrega una etiqueta y su valor directo desde la base de datos sin darle formato a nuestros datos.

[ActiveAdmin Addons](https://github.com/platanus/activeadmin_addons) intenta solucionar ese problema consolidando en una gema múltiples mejoras de UI para mostrar y editar nuestra información.

<!--more-->

## ¿Para qué sirve especificamente?

Actualmente esta gema trae 11 mejoras de UI las cuales se pueden agrupar de la siguiente manera:		

- **[Select2](https://select2.github.io/) reemplaza los dropdown nativos de html**, dándonos la posibilidad de búsqueda tanto con datos locales como por ajax, aparte de poder usar etiquetas (selección múltiple).
- **Filtro por rango númerico**. ActiveAdmin trae un filtro por rango entre fechas pero no incluye manera de encontrar entradas entre dos valores numéricos.
- **Integración con [Paperclip](https://github.com/thoughtbot/paperclip)** para mostrar previews de imágenes y otros documentos.
- Uso de las etiquetas de ActiveAdmin para datos **enum** y **[ASSM](https://github.com/aasm/aasm)**.
- **Formato personalizable de datos**: booleanos y números.
- **Listas html** para `Array` y `Hash`
- **Selector de colores**

Mientras la instalación incluye todas las mejoras, el uso de cada una es 100% opcional como veremos más adelante.

## Instalación

_Todas las instrucciones a continuación asumen que tienes ActiveAdmin instalado y configurado para trabajar con tus modelos._

Si seguimos el [readme](https://github.com/platanus/activeadmin_addons/blob/master/README.md) lo primero es instalar la gema usando bundle:

```ruby
# Gemfile
gem 'activeadmin_addons'
```

```shell
bundle install
```

Una vez instalada hay dos opciones:

1. Se puede ejecutar el generador
   `rails g activeadmin_addons:install`
2. O se pueden realizar los cambios [manualmente](https://github.com/platanus/activeadmin_addons/blob/master/docs/install_generator.md).

## Uso

A continuación veremos como implementar algunas de las mejoras más interesantes.

### Select2

![activeadmin_addons_2a](/images/activeadmin_addons/activeadmin_addons_2a.png)



![activeadmin_addons_2b](/images/activeadmin_addons/activeadmin_addons_2b.png)

Una vez instalada la gema todos los dropdown comenzarán a utilizar Select2 automáticamente lo que por defecto nos permite buscar dentro de los datos locales.

#### Búsqueda por Ajax

Para sacar los datos de otra parte se puede hacer lo siguiente:

```ruby
# Sin ajax
f.input :category_id, as: :select, collection: Category.all {|category| [category.name, category.id] }

# Con ajax
f.input :category_id, as: :search_select, url: admin_categories_path, fields: [:name]
```

Para el campo `url` estamos usando un helper de ActiveAdmin que automáticamente nos da la url para el index de las categorías y como Select2 pide un JSON eso es lo que le entrega.

`fields` representa qué campos en el json se van a buscar, por defecto es `:name` pero si el recurso no tiene esa columna el proceso fallará. Lo mismo ocurrirá con el campo opcional `display_name` que es lo que se muestra en el select.

#### Tags (Selección múltiple)

 ![select2-tags](/images/activeadmin_addons/select2-tags.gif)

```ruby
f.input :number, as: :tags, collection: ["1", "2"]
```

Ojo, no es lo mismo que `:has_many`, no crea relaciones entre tablas sino que produce una string concadenada con `,`.



#### Dropdowns anidados

A la hora de filtrar datos ActiveAdmin Addons trae la posibilidad de anidar dropdowns, haciendo dependiente la carga de resultados de una selección anterior.

 ![select2-nested-select-default](/images/activeadmin_addons/select2-nested-select-default.gif)

```ruby
f.input :city_id, as: :nested_select, fields: [:name],
                  level_1: {
                    attribute: :country_id
                  },
                  level_2: {
                    attribute: :region_id
                  },
                  level_3: {
                    attribute: :city_id,
                    minimum_input_length: 1,
                    fields: [:name, :information]
                  }
```

El código anterior automáticamente carga los resultados del `index` de ActiveAdmin de cada recurso, al igual como lo hacía `admin_categories_path` más arriba.



### Etiquetas

ActiveAdmin trae _status tags_ (  ![tag](/images/activeadmin_addons/tag.png)) que por defecto se pueden usar de la siguiente manera con _enum_:

```ruby
column :status do |d|
  status_color = {
    closed: 'ok',
    pending: 'yes',
    created: 'error'
    }
  status_tag(d.status, status_color[d.status.to_sym])
end
```

En vez de estar creando un bloque por cada etiqueta, ActiveAdmin Addons resume la funcionalidad en una sola función:

```ruby
tag_column :status
```



### Paperclip

La integración con Paperclip es otro ejemplo de como ActiveAdmin Addons reduce el código que tenemos que escribir para lograr los resultados que queremos.

Por defecto para poder mostrar una imagen en el `index` de un modelo en ActiveAdmin se tendría que hacer algo así:

```ruby
column :photo do |c|
  image_tag(c.photo.url(:thumb))
end
```

Con ActiveAdmin Addons se reduce a una linea:

```ruby
image_column :photo, style: :thumb
```

 ![paperclip_index](/images/activeadmin_addons/paperclip_index.png)



De igual manera, para mostrar en una fila en `show` se usaría lo siguiente con ActiveAdmin Addons

```ruby
image_row :photo
```

 ![paperclip_show](/images/activeadmin_addons/paperclip_show.png)



### Selector de Colores (Color picker)

 ![color-picker-colors](/images/activeadmin_addons/color-picker.gif)

En vez de programar esta herramienta desde cero, ActiveAdmin incluye  [JQuery Palette Color Picker](https://github.com/carloscabo/jquery-palette-color-picker), y lo hace fácilmente configurable desde el recurso:

```ruby
f.input :color, as: :color_picker
```

Una opción interesante es poder limitar la paleta de colores, ya sea en el modelo:

 ![color.picker-atom](/images/activeadmin_addons/color.picker-atom.png)

```ruby
f.input :color, as: :color_picker, palette: Invoice.colors
```

o en un array directo:

```ruby
f.input :color, as: :color_picker, palette: ["#DD2900","#D94000","#D55500","#D26A00","#CE7D00","#CA9000","#C6A300","#C2B400","#B9BF00"]
```

Las dos opciones logran el mismo resultado: ![color-picker-palette](/images/activeadmin_addons/color-picker-palette.gif)

Para más información sobre ActiveAdmin Addons el [readme](https://github.com/platanus/activeadmin_addons/blob/master/README.md) del proyecto cubre lo incluido acá y mucho más.
