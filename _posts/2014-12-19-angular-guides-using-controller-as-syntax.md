---
title: "Angular Guides: controller as syntax"
layout: post
author: 
    - emilioeduardob
    - blackjid
categories: 
    - angularjs
    - styleguides
---

Angular nos provee una manera alternativa de definir los controladores llamada `controller as`, esta puede ser usada en la directiva `ng-controller`.

> Estas practicas estan tomadas del [angularjs-styleguide] de John Papa.

### En la vista

- Promueve el uso de objetos con "punto" en la vista (e.g `customer.name` o`vm.name`) en vez de `name`, de esta manera nos ahoramos el posible problema que se rompa el binding por perdese la referencia al valor.
- Ayuda a evitar el usar la propiedad `$parent` para acceder a otros controlladores.

```html
{% raw %}
<div ng-controller="CustomerCtrl as vm">
   {{ vm.name }}
</div>
{% endraw %}
```

> [John Papa's Styleguide: controllerAs View Syntax][view-controller-as]

### En el controllador
- Usamos el controllador como un objecto que se instancia con `new` y asi usamos `this` adentro del controlador.

```js
angular
    .module('myApp')
    .controller('CustomerCtrl', Customer);

    function Customer(){
        this.name = "Pelagio Pavez"
    }

```

La idea de usar `controller as` es dejar de usar el `$scope` como el objecto que relaciona nuestra vista con el controlador, en vez de eso es el mismo controlador el que usamos desde nuestra vista. 

> [John Papa's Styleguide: controllerAs Controller Syntax][ctrl-controller-as]

### Controller as vm?

Podemos usar cualquier nombre para la variable con que accedemos al controller, pero una buena convencion es usar `vm`. Esto viene de viewmodel, que es el modelo que usaremos en nuestra vista.

> [John Papa's post: controllerAs as vm][controller-as-vm]

### Y que pasa con el `$scope`? 

Ojala no lo usemos en el controllador, sin embargo esto no significa que no podamos o este prohibido usar el servicio `$scope`. Este aún tiene sentido, si lo usamos como un servicio que nos provee de metodos como `$watch`, `$broadcast`, etc. especialmente si lo usamos dentro de algun servicio o factory, el cual llamamos desde el controlador.


# Casos reales

A veces en la vida real las cosas son un poco mas complejas que en la teoría. 

### Ionic Popup

La directiva de [popup de ionic][ionic-popup] nos pide que le entreguemos un `$scope` que se usara como contexto para el popup. 

Este es un buen caso para darnos cuenta que no hay problema en seguir usando el servicio `$scope`, podemos pasarle un scope a la directiva independientemente que ya no usemos `$scope` como binding a nuestra vista.

<p data-height="268" data-theme-id="0" data-slug-hash="EaKXjE" data-default-tab="result" data-user="blackjid" class='codepen'>See the Pen <a href='http://codepen.io/blackjid/pen/EaKXjE/'>Ionic Popup with Controller As</a> by Juan Ignacio Donoso (<a href='http://codepen.io/blackjid'>@blackjid</a>) on <a href='http://codepen.io'>CodePen</a>.</p>
<script async src="//assets.codepen.io/assets/embed/ei.js"></script>

### ui-router

Para usar `controller as` en ui-router, solamente definimos, al igual que en la vista, el nombre de la variable con la cual podemos acceder al controlador.

```js
$stateProvider.state('contacts', {
  template: ...,
  controller: 'ContactsCtrl as vm'
})

```

[angularjs-styleguide]: https://github.com/johnpapa/angularjs-styleguide
[view-controller-as]:https://github.com/johnpapa/angularjs-styleguide#style-y030
[ctrl-controller-as]:https://github.com/johnpapa/angularjs-styleguide#style-y031
[controller-as-vm]: http://www.johnpapa.net/angularjss-controller-as-and-the-vm-variable/
[ionic-popup]: http://ionicframework.com/docs/api/service/$ionicPopup/
