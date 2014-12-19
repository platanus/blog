---
title: "Cache con Rails API"
layout: post
author:
    - emilioeduardob
    - ldlsegovia
categories:
    - rails
    - cache
---

## El problema

Muchas veces nos encontramos con endpoints que tienden a ser lentos: debido a cálculos complejos, renderizado
lento de la vista o JSON, volúmen grande de datos, etc.

## Una solución posible usando Http Cache

Http Cache es un standard que consiste en utilizar los `Headers` en conjunto con los `response codes` de un request
para determinar si la copia de los datos que tiene el cliente(Browser, Http Client, etc) está desactualizada. Si
es así, se servirá una nueva copia del recurso, sino se utilazará el mismo(cacheado).

Supongamos que tenemos una API que tiene un endpoint `/api/v1/channels/:id` que devuelve JSON y se demora en la
respuesta 2000 ms, la idea es hacer que el request quede cacheado y no tenga que ser procesado por completo.

### El flujo es el siguiente:

1. Hago un request `GET /api/v1/channels/test`
2. Luego de 2000ms el servidor devuelve los datos con el Response Code 200
3. El browser(u otro cliente) almacena la información en el cache
4. Hago un nuevo request a la misma URL
5. El servidor toma los Headers del request y verifica que el recurso no cambio
6. Luego 8ms el servidor devuelve un request vacio con Response Code `304: Not modified`

## Http Cache usando Rails

### Estado actual del endpoint

Suponiendo que esta es la implementación actual del ejemplo anterior sin cache

```ruby
  def show
    @channel = Channel.find(params[:id])
    respond_with @channel
  end
```

Como queremos cachear este recurso, vamos a utilizar `stale?`. Este método determina, utilizando los Headers
`Last-Modified`(fecha de modificación del recurso) y/o `ETag`(Es un checksum del recurso), si el recurso debe
ser cacheado o no.

Asi quedaria la implmentación:

```ruby
  def show
    @channel = Channel.find(params[:id])
    respond_with @channel if stale? @channel
  end
```

De esta manera, logramos reducir el tiempo de respuesta de este endpoint, ya que aunque el SQL de la busqueda
del channel se ejecuta, el renderizado no.




[angularjs-styleguide]: https://github.com/johnpapa/angularjs-styleguide
