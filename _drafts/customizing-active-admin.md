---
layout: post
title: Personalizando la interfaz de Active Admin
author: arturopuente
tags:
  - rails
  - active-admin
  - ui
---

La interfaz inicial de ActiveAdmin, al ser genérico (y pensando originalmente sólo para ser un CRUD), no permite que podamos hacer resaltar los aspectos más importantes de nuestras aplicaciones. Ahora vamos a ver unos tips para darle un poco de cariño al aspecto visual de los admins.

Para este ejemplo, vamos a crear una aplicación de prueba que se encarga de monitorear el estado de las aplicaciones móviles en algún AppStore.

## Primeros Pasos

En Potassium al instalar ActiveAdmin ya se incluye por defecto `active_skin` (también está en la mayoría de proyectos existentes), si no, hay que agregarlo al Gemfile:

```ruby
gem "active_skin"
```

Una vez instalada la gema, al cargar el administrador se va a ver así:

![Interfaz inicial](/images/customizing-active-admin/default-ui.png)

Lo ideal aquí es agregarle un logo, cambiar un poco el esquema de colores para que combine con el logo o el motivo de la aplicación, e incluso agregar un favicon (que muchas veces se nos olvida en el admin).

Empezando por el logo, lo primero es agregar la imagen a los assets y configurarla en el inicializador de ActiveAdmin:

```ruby
config.site_title_image = "platanus-admin-logo.png"
```

Esto mostrará el logo, sin embargo, la gema de Active Skin no reemplaza el logo, sino que lo superpone al de Active Admin, para solucionarlo debemos con incluir este CSS al final del archivo `app/assets/stylesheets/active_admin.scss`:

```scss
#header h1.site_title {
  text-indent: 0%;
  padding-left: 30px;

  img {
    height: 25px;
    margin-top: 7px;
  }
}
```

Y agregar esta variable debajo de las que están definidas en la parte superior:

```scss
$skinLogo: none;
```

Lo siguiente es cambiar un poco el esquema de colores, en esas variables de Active Skin están los colores que usan en el theme:

```scss
$skinActiveColor: #40AA52;
$skinHeaderBck: #194320;
$panelHeaderBck: #F9BB13;
```

Así se ve el admin con estos cambios:

![Nuevo logo y colores](/images/customizing-active-admin/platanus-admin.png)

## Personalizando los recursos

Esta es la vista de las aplicaciones, que contienen detalles sobre las versiones y una imagen de las aplicaciones:

![Recursos](/images/customizing-active-admin/resources-default-admin.png)

Para ActiveAdmin todos los campos tienen igual valor, por lo tanto no puede diferenciar los que debería resaltar de los que no nos son tan útiles en el index, entonces vamos a empezar por limpiar un poco esta vista:

![Recursos](/images/customizing-active-admin/resources-clean.png)

Ahora tenemos los datos más importantes visibles y los filtros no incluyen una lista maratónica de opciones, sino las más relevantes a las aplicaciones.

En el detalle de los recursos la interfaz por defecto nos muestra solamente una lista de atributos:

![Recursos](/images/customizing-active-admin/resource-detail-default.png)

Aquí es donde dependiendo de la aplicación que tengamos y el diseño que queramos lograr nos bastará con usar los paneles por defecto o utilizar un partial de Arbre. Vamos a crear un partial y referenciarlo desde el bloque `show` en el archivo de admin de las aplicaciones:

```ruby
show do
  render partial: "show", locals: { app: resource }
end
```

Vamos a iniciar con dos columnas, una con datos básicos y otra que tiene un gráfico sobre el estado de la aplicación:

```ruby
columns do

  column do
    panel "Basic information" do
      attributes_table_for app do
        row :name
        row :store
        row :company
        row :version
        bool_row :active
      end
    end
  end

  column do
    panel "Historical progress" do
      render "progress_report"
    end
  end
end
```

El resultado se ve así, pero este diseño puede mejorarse: la columna de la izquierda ocupa demasiado espacio en relación al contenido que muestra, ese espacio beneficiaría mucho a la de la derecha.

![Detalle de la aplicación](/images/customizing-active-admin/resource-detail-two-columns.png)

Para solucionar esto vamos a realizar los siguientes cambios:

- Editamos el archivo `_show.arb` para añadir un par de clases de CSS a las columnas (podríamos deducirlo usando algún selector nth pero es preferible ser explícito en este caso):

```ruby
columns do

  column class: "column small-column" do
    panel "Store information" do
      image_tag app.picture.url(:thumb)
    end

    panel "Basic information" do
      attributes_table_for app do
        row :name
        row :store
        row :company
        row :version
        bool_row :active
      end
    end
  end

  column class: "column big-column" do
    panel "Historical progress" do
      render "progress_report"
    end
  end
end
```

- Ahora añadimos lo siguiente al archivo de CSS de Active Admin:

```css
.column.small-column {
  width: 25% !important;
}

.column.big-column {
  width: 73% !important;
}
```

Y ahora tenemos una interfaz mucho más ordenada que nos permite visualizar la información importante de nuestros modelos:

![Detalle de la aplicación](/images/customizing-active-admin/resource-bigger-columns.png)

El código fuente para poder revisar el resultado final se encuentra en este repositorio [platanus/active-admin-ui-example](https://github.com/platanus/active-admin-ui-example)
