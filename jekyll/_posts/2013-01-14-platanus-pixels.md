---
title: Platanus Pixels
author: sbaixas
layout: post
categories:
  - canvas
  - javascript
---

![Platanus Pixels][1]

[1]: /images/platano-pixeles.jpg

En mi pasantía veraniega en Platanus, hice un lab que consiste en la animación interactiva de una imagen (predeterminada) que se descompone y luego recompone en pixeles dependiendo de los movimientos y clicks del mouse. Pueden ver el resultado [aquí][2] y el código, en el [repositorio][3]

[2]: http://platanus-repos.github.com/sebis-balls/
[3]: https://github.com/platanus-repos/sebis-balls

Para este lab utilicé [d3js][4] como ayuda para ordenarme y [jquery][5] para los controles y eliminar el canvas más fácilmente. El funcionamiento se divide en 3 partes importantes.

[4]: http://d3js.org/
[5]: http://jquery.com

### El Comportamiento de Persecución-Escape de los pixeles

Este es el principal desafío del programa, para empezar creé un constructor de objetos con coordenadas *x* e *y* (como una ficha de ajedrez) y una velocidad de movimiento por turno o “tick”de la simulación

```javascript
function Pawn(x, y, ms)
{
    this.x = x;
    this.y = y;
    this.ms = ms;
}
```

para poder representar los pixeles en una posición especifica y hacer variar la misma, si solo utilizamos este principio tendríamos objetos(ya sean pixeles de una imagen, círculos, cuadrados, imágenes, etc…) que podríamos mover con una conducta de condicionales simple como esta.

```javascript
/*creamos una función que toma un objeto y las coordenadas
del destino*/
function move(pawn, destX, destY)
{
    /*guardamos los valores de las coordenadas y la
    velocidad de nuestro objeto*/
    var x = pawn.x;
    var y = pawn.y;
    var ms = pawn.ms;
    /*si el valor de x de nuestro objeto es menor
    que el del destino*/
    if(x < destX)
    {
        //incrementamos x
        x =ms;
    }
    //sino, chequeamos si es menor, y si lo es
    else if(x > destX)
    {
        //disminuimos x
        x-=ms;
    }
    //luego lo mismo para y
    if(y < destY)
    {
        y =ms;
    }
    else if(y > destY)
    {
        y-=ms;
    }
    object.x = x;
    //seteamos los nuevos x e y
    object.y = y;
    //devolvemos el objeto
    return object;
}
```

Lo cual iterando produciría un movimiento poco fluido e irregular.

![discreto][6]

[6]: /images/platano-pixeles-mov-basico.jpg "Movimiento de Coordenadas"

En este caso moverse *ms* en una dirección toma la misma cantidad de tiempo que para moverse raíz cuadrada de (2x*ms*x*ms*) es decir que existe un problema con todos los movimientos que no están alineados con los ejes x o y. Para solucionar este problema se necesita una dirección aparte de las coordenadas y la velocidad de movimiento par así poder (por medio de trigonometría) cambiar x e y acorde a la distancia total que queremos que se desplace el objeto en un “tick”.

```javascript
function Pawn(x, y, ms, angle)
{
    this.x = x;
    this.y = y;
    this.ms = ms;
    //primero añadimos el atributo angle (ángulo) a
    nuestro objeto
    this.angle = angle;
}

function vectorialAdvance(object)
{
    //almacenamos la velocidad en una variable
    var ms = object.ms;
    //la dirección actual en otra
    var angle = object.angle;
    /*multiplicamos el coseno de la dirección por la
    distancia que queremos que se mueva en esa
    dirección lo cual equivale al desplazamiento
    en x */
    object.x  = Math.cos(angle)*ms;
    object.y  = Math.sin(angle)*ms;
    /*multiplicamos el seno de la dirección por la
    distancia que queremos que se mueva en esa
    dirección lo cual equivale al desplazamiento
    en y*/
    //retornamos el objeto
    return object;
}
```

Si llamamos a la función *vectorialAdvance* repetidamente tenemos que el objeto avanzará exactamente *ms* pixeles de distancia por “tick” de simulación.

![vectorial][7]

 [7]: /images/platano-pixeles-vectores.jpg "Movimiento Vectorial"

Esto produce un movimiento uniforme en cualquier dirección, pero hasta ahora solo en línea recta, el próximo problema es hacer que nuestro objeto tenga un punto de destino, para lo cual podemos usar la siguiente función.

```javascript
function follow(destX,destY,object)
{
    var x = object.x;
    var y = object.y;
    var difX = destX - x;
    var difY = destY - y;
    /*Esta es la formula para el angulo en radianes
    dada una pendiente, pero es necesario hacer
    ajustes para los cuadrantes 2, 3 y 4 con
    respecto a las coordenadas del objeto*/
    var followAngle = Math.atan(difY/difX);
    //Ajustamos el ángulo a su menor valor posible
    while(followAngle > Math.PI * 2)
    {
        followAngle -= Math.PI * 2;
    }
    /*Si el angulo esta en el primer cuadrante lo
    dejamos como está*/
    if(difX > 0 && difY > 0)
    {
    }
    //Si esta en el segundo cuadrante
    else if(difX > 0 && difY < 0)
    {
        //Le sumamos 2*PI radianes (360 grados)
        followAngle  = Math.PI*2;
    }
    /*Si esta en el tercero o el cuarto le sumamos
    PI radianes (180 grados)*/
    else if(difX < 0 && difY > 0)
    {
        followAngle  = Math.PI;
    }
    else
    {
        followAngle  = Math.PI;
    }
    object.angle = followAngle;
}
```

Hasta ahora nuestro objeto se mueve a un punto (x,y) con la velocidad como única limitante. Para añadir realismo consideraremos los factores de aceleración y velocidad angular, es decir nuestro objeto parte del reposo, ganando velocidad y siendo capaz de cambiar su angulo en una cantidad máxima por “tick” de simulación.

Primero modificamos nuestro objeto

```javascript
function Pawn(x, y, maxMs, angle, acc, as)
{
    this.x = x;
    this.y = y;
    //Seteamos nuestra velocidad en 0;
    this.ms = 0;
    //Le asignamos una variable a la aceleración
    this.acc = acc;
    /*Le asignamos una variable a la velocidad
    máxima que nuestro objeto puede tener*/
    this.maxMS = maxMS;
    /*Le asignamos una variable a la velocidad
    angular*/
    this.as = as;
    this.angle = angle;
    /*Le damos a nuestro objeto un método para
    acelerar*/
    this.accelerate = function()
    {
        /*Si se pasa de la velocidad máxima
        acelerando*/
        if(this.ms   this.acc >= this.maxMs)
        {
            /*Su velocidad de movimiento es
            igual a la máxima*/
            this.ms = this.maxMs;
        }
        //Sino
        else
        {
            //Acelera normalmente
            this.ms  = this.acc;
        }
    }
}
```

Luego nuestra función para modificar el ángulo

```javascript
function follow(destX,destY,object)
{
    var x = object.x;
    var y = object.y;
    /*almacenamos en variables el ángulo
    actual del objeto*/
    var angle = object.angle;
    // y la velocidad angular
    var as = object.as;
    var difX = destX - x;
    var difY = destY - y;
    //este ahora es el ángulo a seguir
    var followAngle = Math.atan(difY/difX);
    /*dejamos el ángulo entre 0 y 2*PI
    radianes(360 grados)*/
    while(angle > Math.PI * 2)
    {
        angle -= Math.PI * 2;
    }
    while(angle < 0)
    {
        angle  = Math.PI * 2;
    }
    //hacemos los ajustes pertinentes
    while(followAngle > Math.PI * 2)
    {
        followAngle -= Math.PI * 2;
    }
    if(difX > 0 && difY > 0)
    {
    }
    else if(difX > 0 && difY < 0)
    {
        followAngle  = Math.PI*2;
    }
    else if(difX < 0 && difY > 0)
    {
        followAngle  = Math.PI;
    }
    else
    {
        followAngle  = Math.PI;
    }
    /*este ajuste es para que encontrar el
    camino mas corto, ya que si uno esta muy
    cercano a 0 y el otro a 360 daría toda la
    vuelta*/
    if(followAngle - angle > Math.PI)
    {
        angle  = Math.PI*2;
    }
    /*Lo mismo que el último comentario pero
    cambiando un ángulo por el otro*/
    if(angle - followAngle > Math.PI)
    {
        followAngle  = Math.PI*2;
    }
    /*solucionado eso, si el ángulo a seguir
    es menor, le restamos la velocidad
    angular*/
    if(angle > followAngle)
    {
        /*esto es parecido a lo que hicimos
        con la aceleracion, si nos estamos
        pasando igualamos el angulo a seguir*/
        if(Math.abs(angle - followAngle) < as)
        {
            angle = followAngle;
        }
        else
        {
            angle -= as;
        }
    }
    //si es mayor, se la sumamos
    else if(angle < followAngle)
    {
        if(Math.abs(angle - followAngle) < as)
        {
            angle = followAngle;
        }
        else
        {
            angle  = as;
        }
    }
    object.angle = angle;
    return object;
};
```


Si al punto de destino le asignamos las coordenadas del mouse hacemos que nuestro objeto siga al mouse de manera fluida y con todas sus limitaciones

### La descomposición de la imagen en pixeles

Para esto necesitamos un canvas, ya que javascript no nos permite extraer datos de la imagen directamente (fuera del largo y el ancho), para poder usar datos de imágenes es *necesario* un dominio, en mi caso use un servidor HTTP simple provisto por python, y luego lo subí a github pages que tiene su propio dominio, de no tener dominio le consola puede dar una excepción de seguridad (lo que me tomo bastante tiempo solucionar).

Volviendo al código, hice lo siguiente.

Primero creamos el constructor de un nuevo objeto, que representa a un pixel y su ubicación.

```javascript
function Pixel(r, g, b, x, y)
{
    this.r = r;     //rojo
    thig.g = g;     //verde
    thig.b = b;     //azul
    thig.x = x;     //coordenada x
    thig.y = y;     //coordenada y
}
```

Luego cargamos la imagen, la ponemos en un canvas, guardamos los datos del canvas y eliminamos el canvas. Los datos de la imagen son un arreglo de bytes (números entre 0 y 255) ordenados de tal manera r,g,b,a,r,g,b,a… y repitiéndose así infinitamente donde cada r es el valor del color rojo de un pixel, g el valor del color verde, y b el valor del color azul, el a es el *alpha* de cada pixel y representa la transparencia, en este lab en particular no lo estoy usando.

```javascript
//creamos el objeto de la imagen
var img = new Image();
/*le asignamos el path de la imagen que
queremos usar*/
img.src = "d3/img.jpg";
//creamos un arreglo vacío de pixeles
var pixels = [];
//esperamos a que se cargue la imagen
img.onload = function ()
  {
    //guardamos el contexto del canvas
    var context = document.getElementById('canvas').getContext('2d');
    /*redimensionamos el canvas al porte
    específico de la imagen*/
    canvas.width = img.width;
    canvas.height = img.height;
    /*hacemos que el contexto dibuje la
    imágen en el canvas*/
    context.drawImage(img, 0, 0);
    /*guardamos en un objeto los datos
    de todo lo dibujado en el canvas
    (en este caso sólo la imagen)*/
    var imgData = context.getImageData(0, 0, canvas.height, canvas.width);
    /*inicializamos las coordenadas
    en 0*/
    var x = 0, y = 0;
    /*hacemos un for para recorrer el arreglo
    de bytes, pero que salte de a 4 valores*/
    for(i = 0; i < imgData.data.length; i =4){
          /*el primer valor se lo
          asignamos al rojo, el
          segundo al verde, el
          cuarto al azul y luego
          los valores de las
          coordenadas que
          modificamos en cada
          vuelta del for*/
          pixels.push(new Pixel(imgData.data[i],imgData.data[i 1],imgData.data[i 2],x,y))
          //aumentamos x
          x  ;
          /*si x es mayor o igual
          al ancho de la imagen
          reiniciamos x
          , y aumentamos y*/
          if(x >= img.width)
            {
            y  ;
            x = 0;
            }
        }
        /*terminando este for
        el arreglo contiene todos
        los pixeles de la imágen*/
    /*nos deshacemos del canvas
    que ocupa espacio en nuestra
    página(con jquery)*/
    $('canvas').remove();
```

después de esto tenemos un arreglo de pixeles con sus coordenadas respectivas listo para ser usado.

### La generación de los gráficos con d3js

combinar las partes anteriores y mostrar todo use d3js, con la siguiente estructura

```javascript
/*esperamos a que se termine de cargar la
ventana antes de empezar a ejecutar el
código*/
window.onload = function()
{
 /*guardamos en variables el ancho y el
 largo de la ventana al momento de
 cargarse*/
 var width = window.innerWidth;
 var height = window.innerHeight;
 var dataset = [];
 //seleccionamos el body
 var svg = d3.select("body")
     //le añadimos un svg
     .append("svg")
     /*modificamos el svg para que tenga
     las dimensiones de nuestra ventana
     actual*/
     .attr("width", width)
     .attr("height", height);
 //le asignamos toda la inicializacióna una funcion
 function displ()
 {
   var pixs = svg
    /*seleccionamos todos los rectángulos
    (todavía no hay ninguno)*/
    .selectAll("rect")
    /*en esta parte proveemos un arreglo
    de objetos, por cada objeto en el
    arreglo se va a  generar un nuevo
    rectángulo, las dimensiones pueden
    depender o no de los datos del
    objeto*/
    .data(dataset)
    /*esta linea crea un rectángulo por
    cada objeto del arreglo que no está
    asignado a un rectángulo (en este
    caso los crea todo)*/
    .enter()
    /*se añade el rectángulo al svg con
    los soguientes atributos*/
    .append("rect")
    /*d representa al objeto correspondiente
    en el dataset. Basicamente hay que poner
    de alguna manera en el dataset objetos que
    tengan atributos usables en esta parte, para
    este ejemplo estoy usando objetos "pawn"
    definidos en la primera parte, pero con 2
    atributos añadidos, color y tamaño, y el
    color es asignado por la lista de pixeles
    obtenida en la segunda parte*/
    .attr("x", function(d) { return d.x; } )
    .attr("y", function(d) { return d.y; } )
    .attr("width", function(d) { return d.size/2; } )
    .attr("height", function(d) { return d.size/2; } )
    .attr("fill", function(d){ return d.color; });
 }
 //llamamos al método recién definido
 displ();
 /*definimos el método update para que haga todos
 los cambios que queremos en los objetos*/
 function update()
 {
    /*modificamos cada uno de los objetos del
    dataset con sus métodos respectivos*/
    for (var i = 0; i < dataset.length; i  ) {
       /*utilizamos los métodos creados en la
       primera parte*/
       dataset[i].accelerate();
       dataset[i] = vectorialAdvance(dataset[i]);
       dataset[i] = follow(width/2, height/2, dataset[i]);
   };
   //seleccionamos todos los rectángulos
   svg.selectAll("rect")
   //les pasamos el dataset actualizado
   .data(dataset)
   //actualizamos las coordenadas
   .attr("x", function(d) { return d.x; })
   .attr("y", function(d) { return d.y; });
 }
 /*hacemos que update se llame indefinidamente
 cada 5 milisegundos*/
 window.setInterval(update,5);
}
```

y así tenemos pixeles que se mueven, a un punto determinado en el medio de la pantalla y tratan de permanecer lo mas cerca posible de el dadas sus limitaciones de velocidad angular e incapacidad para frenar, los métodos que faltan son break de la clase Pawn que se encuentra como Duck en el repositorio y el resto de las funciones de movimiento vecotorial stalk, realign y scape que se encuentran también en el repositorio en el archivo vectorialMovement.js