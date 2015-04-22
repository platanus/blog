---
title: Generador Platanus de aplicaciones Ionic
layout: post
author: renemoraales
tags:
    - angular
    - ionic
    - cordova
redirect_from: angularjs/ionic/2015/04/10/generador-platanus-de-aplicaciones-ionic.html
---

**Ionic** es nuestro framework *de facto* para fabricar aplicaciones móviles en Platanus. Nos permite crear buenas experiencias con las herramientas a las que estamos acostumbrados a trabajar, es multiplataforma y es rápido para desarrollar. 

Pero cada proyecto nuevo involucraba una manera distinta de manejar el flujo de desarrollo, assets y compilación. Se trabajó una solución basada integramente en Gulp, pero este approach se alejaba cada vez más del flujo sugerido por Ionic. Además, las estructuras de carpetas no eran consistentes, y en el fondo, todas estas diferencias complican el trabajo en equipo.

Finalmente, la falta de un proceso bien establecido alargaba el proceso de preparación del proyecto por sobre lo necesario, en desmedro de comenzar lo antes posible el desarrollo en sí.

Así que, como parte del proceso de definir una metodología de trabajo, **creamos un [generador basado en Yeoman](https://github.com/platanus/generator-platanus-ionic)**, que nos permite fabricar aplicaciones basadas en Ionic y nuestras prácticas comunes con rapidez, al mismo tiempo que nos apegamos lo más posible a las sugerencias del equipo de Ionic, aprovechando las ventajas de su CLI.

## El rol del App Base y Template

Existen dos repositorios complementarios al generador, nuestro **[App Base](https://github.com/platanus/ionic-app-base)**, y **[Starter Template](https://github.com/platanus/ionic-starter-template)**. Estos proyectos contienen el código que compone la base de una aplicación:

- **App Base** contiene nuestro punto de partida para fabricar aplicaciones Ionic, incluyendo la estructura básica de carpetas y algunos archivos fundamentales. Por ejemplo, archivos como bower.json, package.json, .gitignore u  otros van aquí. Además, incluye una serie de tareas Gulp que ayudan a facilitar el flujo de servir y compilar la aplicación.
- **Template** es el código base de la aplicación misma, con controladores, vistas, assets, etc. Esta separación es importante pues nos ayuda a ajustarnos rápidamente entre distintos casos de uso, como aplicaciones con menú lateral, otras basadas en pestañas, etc.

Tener estas dos piezas en repositorios separados nos ayuda a iterar más rápido, entendiendo que cambios en archivos de referencia como un .gitignore no tienen relación con el proceso que lleva a cabo el generador mismo.

## Generando una aplicación

Instalarlo es tan simple como uno, dos:

1. ```npm install -g yo```
2. ```npm install -g generator-platanus-ionic```

Luego de instalado, basta con entrar a un directorio vacío y correr ```yo platanus-ionic```. Este comando reemplaza al ```ionic start``` del CLI oficial, y es el único momento en el que no lo utilizaremos como nuestra herramienta principal. Primero, nos preguntará los detalles sobre nuestra aplicación:

![Generator](http://i.imgur.com/gIVz6HF.png)

Y a continuación, el generador...

- descargará el App Base y Template correspondientes,
- guardará el nombre y ID de la aplicación especificado en los archivos correspondientes (ionic.project, bower.json, package.json, etc),
- agregará un proxy con la URL especificada al ionic.project,
- descargará todas las dependencias (npm y bower) del proyecto, agregando algunas recomendadas,
- añadirá soporte para las plataformas especificadas,
- configurará Crosswalk si es necesario,
- instalará algunos plugins de Cordova recomendados,
- y te informará amistosamente que el proceso finalizó.

Luego de este paso, ya puedes correr ```ionic serve``` para ver la aplicación en el navegador.

## Desarrollando

Hemos querido modificar lo menos posible el flujo recomendado por Ionic para trabajar las aplicaciones, por lo que, en términos generales, el flujo no debiese ser muy distinto al de una aplicación generada con la línea de comandos de Ionic. Sin embargo, introdujimos algunas adiciones útiles al proceso:

- Primero, hacemos uso de ```documentRoot```, una propiedad de ```ionic.project``` que nos permite tener el código de la aplicación en una carpeta distinta a ```www```. En este caso, utilizamos ```app```. Con esto podemos procesar los archivos que llegan al build.
- Segundo, tenemos una carpeta ```environments``` con archivos JSON que nos permiten definir distintos "ambientes" con variables que son expuestas a la aplicación a través de una constante de Angular. Ideal para llaves o endpoints de APIs que cambian según el ambiente.
- Tercero, creamos un archivo ```.buildignore``` que nos permite definir fácilmente archivos o carpetas que queremos dejar fuera de las builds nativas del proyecto, como componentes de bower muy pesados, o assets que son utilizados sólo en desarrollo como placeholders, por ejemplo.

Para lidiar mejor con estas particularidades, desarrollamos algunas tareas de Gulp que se integran al flujo existente de ```ionic serve``` y ```ionic build```, evitando tener que correr comandos extra cuando queremos servir o compilar la aplicación. 

## Algunos temas pendientes

Esta es una primera versión de nuestro generador, y al mismo tiempo, de nuestra definición de buenas prácticas. Hemos acordado ya en muchos temas relacionados con la generación de una aplicación, pero todavía queda mucho por avanzar, sobre todo en la estructura de código de la misma: cómo organizaremos nuestros modelos, controladores, directivas, etc., y si estos podrán ser generados también a través de esta herramienta.

Sin embargo, consideramos que es un muy buen punto de partida para comenzar rápidamente a desarrollar aplicaciones y resuelve distintos problemas que hemos enfrentado durante la construcción de éstas. Esperamos que sea de gran ayuda para quienes trabajamos aquí, y por qué no, para el resto del mundo también.
