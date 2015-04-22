---
title: Webcomponents con Polymer
author: emilioeduardob
layout: post
tags:
    - html5
    - webcomponents
    - polymer
redirect_from: html5/webcomponents/polymer/2013/10/23/webcomponents.html
---

WebComponents es una de las tecnologias que particularmente espero con mayor ansiedad ya que con esto, podemos crear nuestros propios elementos HTML(como ser un pagination, rating, etc) y de esta manera reutilizarlos en otros proyectos, o inclusive con la comunidad Open Source.

Para los que no quieren esperar a que el spec WebComponents este finalizado y todos los navegadores lo implementen(Actualmente Chrome tiene soporte inicial), surgio la libreria 'Polymer', esta libreria nos permite usar los WebComponents en cualquier navegador.

Este post mostrara un ejemplo basico de utilizacion de [Polymer][1] y crearemos un componente `pagination`. Y para facilitar aun mas las cosas, utilizaremos [Yeoman][2] para generar la estructura basica.

Lo primero que haremos es instalar el generador de Polymer para yeoman

```bash
npm install -g generator-polymer
```

Ahora creemos nuestro proyecto base para desarrollar nuestro componente.

```bash
mkdir proyecto-prueba
cd proyecto-prueba
yo polymer
```

Esta ultima linea es la que crea toda la estructura inicial de un proyecto HTML5 con polymer ya configurado, yeoman nos preguntara si queremos incluir Twitter Bootstrap en el proyecto, y en este caso elegi Yes

Para generar nuestro primer componente utilizamos el comando `yo` nuevamente

```bash
yo polymer:element pagination
```

Yeoman nos preguntara si queremos importar el elemento al index.html y elegimos Si.

Listo, ya tenemos la estructura lista para empezar. La idea es utilizar el diseño de un pagination que ofrece Boostrap

Bootstrap nos entrega el siguiente HTML para crear un elemento pagination

```html
<div class="pagination">
  <ul>
    <li><a href="#">Anterior</a></li>
    <li><a href="#">1</a></li>
    <li><a href="#">2</a></li>
    <li><a href="#">Siguiente</a></li>
  </ul>
</div>
```

Con WebComponent deberiamos cambiar esa estructura por esta

```html
<pagination-element count="2">
</pagination-element>
```

Para esto modificamos el archivo `pagination-element.html` y deberia quedar asi:


```html
{% raw %}
<polymer-element name="pagination-element"  attributes="count">
  <template>
  <div class="pagination">
    <ul>
      <li><a href="#">Anterior</a></li>
      <template repeat="{{page in pages }}">
      <li><a href="#">{{page}}</a></li>
      </template>
      <li><a href="#">Siguiente</a></li>
    </ul>
  </div>
  </template>
  <script>
  Polymer('pagination-element', {
    count: 5,
    created: function() {
      this.pages = [];
      for (i=1; i<=this.count; i++) {
        this.pages.push(i);
      }
    },
  });
  </script>
</polymer-element>
{% endraw %}

```

Con este codigo, tenemos un nuevo elemento llamado `pagination-element` que acepta un attribute `count` donde definimos el numero de paginas a utilizar.

El template que usamos en polymer muestra la capacidad de databinding que tiene utilizando los `{{}}` para leer las variables definidas en `this`.

Este es un ejemplo muy basico de WebComponent pero deberia dar una idea del potencial que tiene.

[1]: http://www.polymer-project.org/
[2]: http://yeoman.io/
