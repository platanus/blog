---
title: Cuál es el tamaño de una base de datos MySQL
author: Andres
layout: post/andres-arellano
categories:
    - mysql
---

Saber cuánto almacenamiento está utilizando una base de datos es una tarea común. Calcularlo podría ser complicado, ya que naturalmente el cálculo requiere considerar no sólo el número de “filas” en en cada tabla de la base de datos, sino que también el tipo de dato que se almacena en éstas. Afortunadamente no es nada difícil, ya que basta con ejecutar una consulta SQL para obtener la info.

Aquí dejo dos consultas, la primera es para obtener el tamaño por base de dato en un servidor, y la segunda es para obtener el tamaño por tabla, para una base de dato en particular.

<script src="https://gist.github.com/aarellano/4178512.js"></script>
