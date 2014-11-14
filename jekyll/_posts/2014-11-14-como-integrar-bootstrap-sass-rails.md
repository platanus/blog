---
title: Cómo integrar Bootstrap, Sass y Rails sin morir en el intento
author: Arturo Puente y René Morales
layout: post/arturo-puente
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
