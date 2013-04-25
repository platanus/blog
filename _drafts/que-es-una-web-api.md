---
title: ¿Qué es una Web API en términos simples?
author: Agustin Feuerhake
layout: post
categories:
    - api
    - humanos
---

###Explicación para seres humanos de qué es y para qué sirve una API.

<img src="/images/monkey_thinking.gif" style="float:left;width:300px;margin:20px;"/>

Saltémonos las explicaciones lateras y vamos directo a un **ejemplo**: Google Maps tiene una API. El [API de Google Maps][1], entre otras cosas, te ofrece transformar una dirección (calle, número) en un **punto en el mapa** (latitud, longitud). Esta API la usan los desarrolladores de aplicaciones para taxis, de comida a domicilio como [quehambre.cl][2], etc., porque cuando tienes la latitud y longitud, puedes facilmente calcular la distancia entre dos lugares (Ej: casa y restaurante).  Google podría cobrar por usarla, porque ellos tienen un computador conectado a internet que hace el trabajo de transformar las direcciones en puntos, pero como parte de la estrategia de Google es agradar a los programadores, ofrecen el servicio gratis hasta un número de direcciones transformadas por día. 

Los que estudiaron matemática en el colegio recordarán lo que es una **función**. Una función es una cosa que recibe algo, lo procesa y devuelve otra cosa diferente. Tal como te mostré en el ejemplo, transformar una dirección a un punto en el mapa es una función. Una API es un conjunto de funciones.

Tal como la de Google Maps, existen miles de APIs. Por ejemplo, Twitter tiene una API que tiene una función que permite que un programador encuentre Tweets que contienen una palabra específica. También tiene una función para poder saber cuántos followers tiene un usuario, y muchas más. 

Una de las gracias más evidentes de las WEB APIs es que pueden ser usadas por los programadores para construir aplicaciones que aprovechan lo que ya está construido, pero también tiene muchas ventajas para la misma empresa que la ofrece.

[1]: https://developers.google.com/maps/documentation/
[2]: http://www.quehambre.cl