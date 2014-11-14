---
title: Cómo integrar Bootstrap, Sass y Rails sin morir en el intento
author: Arturo Puente y René Morales
layout: default
categories:
    - rails
    - bootstrap
    - sass
---

Bootstrap es actualmente el framework HTML/CSS más popular para construir aplicaciones web responsivas. Incluye una serie de estilos base, componentes y utilidades que son de gran ayuda cuando necesitamos dar forma al front-end de nuestras apps de forma rápida y sencilla.

En este artículo veremos como incluir Bootstrap, en su sabor Sass, a tu aplicación de Rails, y como sacar el mayor provecho a las clases y mixins que éste nos entrega para sazonar los estilos de tus vistas.

## Primeros pasos

Para empezar a usar Bootstrap en tu aplicación de Rails requiere de un proceso de instalación muy simple, el primer paso es añadir al Gemfile la gema de Bootstap.

```ruby
# Gemfile
gem 'bootstrap-sass', '~> 3.3.1'
gem 'autoprefixer-rails'
```

Esto nos dará la última versión de Bootstrap, y prefijos de browsers automáticos (como `-webkit` o `-moz`) en nuestro código. Tras incluirlos, debemos ejecutar un `bundle install` y reiniciar nuestro servidor.

El siguiente paso es eliminar el archivo `app/assets/stylesheets/application.css` y crear uno llamado `app/assets/stylesheets/application.css.scss`, en el que pondremos las siguientes líneas:


```css
/* app/assets/stylesheets/application.css.scss */
@import "bootstrap-sprockets";
@import "bootstrap";
```

El último paso de la instalación consiste en añadir la siguiente línea al archivo `app/assets/javascripts/application.js`

```javascript
//= require bootstrap-sprockets
```
## Usando Bootstrap

Con los pasos anteriores podemos utilizar las clases de Bootstrap en nuestras vistas automáticamente. Para aprovechar los mixins en nuestros assets, debemos primero agregar un `@import “bootstrap”;` antes de nuestro código.

Es importante requerir los archivos adicionales que nuestra aplicación utilice en application.css.scss, de forma que ese archivo quedaría algo así

```css
/* app/assets/stylesheets/aplication.css.scss */
@import "bootstrap-sprockets";
@import "bootstrap";
@import "products"; // Este archivo es nuestro, dentro de app/assets/stylesheets
@import "carts"; // Y este es otro archivo de nuestra app.
```

## Poniéndolo en práctica

Para demostrar cómo podemos sacar mayor provecho de Bootstrap con Sass, hemos creado una simple aplicación donde los habitantes del vecindario pueden registrar a sus gatos, para que el resto de los vecinos los reconozcan y no los maltraten si los ven andando por ahí.

En nuestro ```views/cats/index.html.erb```, donde listamos a los gatos registrados en el servicio, usaremos el siguiente markup con una estructura muy simple y algunas clases que hemos creado. Podemos agregar directamente clases de Bootstrap en nuestros elementos (en este ejemplo, ```pull-right``` en nuestro botón y ```col-sm-3``` para el grid). Esta es la manera "clásica" de usar el framework.

```ruby
<header id="cats-header">
  <%= link_to 'Registrar un gato', new_cat_path, class: 'catlog-button pull-right' %>
  <h1>Gatos del vecindario</h1>
</header>

<section id="cats-container">
  <% @cats.each do |cat| %>
    <div class="col-sm-3">
      <article class="cat">
        <%= image_tag cat.image %>
        <div class="cat-name"><%= cat.name %></div>
      </article>
    </div>
  <% end %>
</section>
```

Pero queremos ir un paso más allá y extender nuestras propias clases con las que nos facilita Bootstrap, usándolas como base y añadiéndole nuestras propias declaraciones. Para esto usaremos ```@extend``` de SCSS:

```scss
@import "bootstrap-sprockets";
@import "bootstrap";

body {
  background-color: #f0f0f0;
}

.catlog-button {
  /* Creamos nuestro .catlog-button basándonos en las clases de bootstrap/_buttons.css.scss */
  @extend .btn, .btn-default, .btn-lg;

  /* Hacemos referencia a los colores definidos en bootstrap/_variables.css.scss */
  background-color: $brand-success;
  border: none; 
  box-shadow: inset 0px -3px rgba(0,0,0,.1);
  color: white;
  margin-top: 16px;
}

#cats-header {
  margin-bottom: 15px;
  padding: 20px 0;

  h1 {
    color: $brand-primary;
    font-weight: 300;
  }
}

#cats-container {
  /* Siguiendo la misma técnica, podemos utilizar cualquier clase disponible en Bootstrap. */
  @extend .row;

  .cat {
    @extend .thumbnail;

    border-color: transparent;
    box-shadow: 0px 2px 5px rgba(0,0,0,.1);
    padding: 30px;

    img { border-radius: 50%; }

    .cat-name {
      color: #666;
      font-size: 15px;
      font-weight: 500;
      padding-top: 15px;
      text-align: center;
    }
  }
}
```

Con este código, nuestro resultado es el siguiente: 

![][1]

Hemos extendido nuestras clases con las de los componentes de bootstrap, como ```.row```, ```.btn``` y ```.thumbnail```, entre otras. Con esto logramos un HTML más limpio y además evitamos cargar todo el framework en nuestra página, asegurándonos que sólo los componentes que nos interesan lleguen a la hoja de estilos después de ser compilada.

[1]: /images/catlog.png
