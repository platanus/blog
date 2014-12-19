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

Muchas veces nos encontramos con endpoints que tienden a ser lentos debido a cálculos complejos, renderizado lento de la vista o JSON, volúmen grande de datos, etc.

## Una solución posible usando Http Cache

Http Cache es un standard que consiste en utilizar los `Headers` en conjunto con los `response codes` de un request para determinar si la copia de los datos que tiene el cliente (Browser, Http Client, etc.) está desactualizada. Si es así, se servirá una nueva copia del recurso, sino se utilazará el mismo (cacheado).

Supongamos que tenemos una API que tiene el endpoint `/api/v1/posts/:id` que devuelve JSON y se demora en la respuesta 2000 ms, la idea es hacer que el request quede cacheado y no tenga que ser procesado por completo.

### El flujo es el siguiente:

1. Hago un request `GET /api/v1/posts/22`.
2. Luego de 2000ms el servidor devuelve los datos con el Response Code 200.
3. El browser (u otro cliente) almacena la información en el cache.
4. Hago un nuevo request a la misma URL.
5. El servidor toma los Headers del request y verifica que el recurso no cambio.
6. Luego de 8ms el servidor devuelve una respuesta vacía con Response Code `304: Not modified`.

## Http Cache usando Rails

### Estado actual del endpoint

Suponiendo que esta es la implementación actual del ejemplo anterior sin cache

```ruby
  def show
    @post = Post.find(params[:id])
    respond_with @post
  end
```

Como queremos cachear este recurso, vamos a utilizar `stale?`. Este método determina, utilizando los Headers `Last-Modified`(fecha de modificación del recurso) y/o `ETag`(Es un checksum del recurso), si el recurso debe ser cacheado o no.

Así quedaría la implementación:

```ruby
  def show
    @post = Post.find(params[:id])
    respond_with @post if stale? @post
  end
```

El ejecutar esta acción devolverá el siguiente resultado:

```json
{
  name: "Cache Rails!",
  created_at: "2013-11-19T21:33:01.000"
}
```

De esta manera, logramos reducir el tiempo de respuesta de este endpoint, ya que, aunque el SQL de la busqueda del post se ejecuta, el renderizado no.

Ahora supongamos que el json que devuelve el endpoint es un poco más complejo. No sólo devuelve los atributos del post sino que  incluye los últimos comentarios de este.

```json
{
  name: "Cache Rails!",
  created_at: "2013-11-19T21:33:01.000"
  comments: [
    { message: 'Hola' id: 2 },
    { message: 'Chau' id: 3 }
  ]
}
```

Cuál es el problema con esto? si se agregan nuevos comentarios estos no se reflejaran en la llamada porque el request está cachado a un nivel superior (el post). Esto sucede porque el método `stale?` utiliza el campo `updated_at` del recurso que esta cacheando y el cambio en los comentarios no modifica la fecha de actualización del post. La solución a este problema consiste en pasar una condición a `stale?` que determine cuando descartar lo cacheado.

```ruby
  def show
    @post = Post.find(params[:id])
    respond_with @post if stale?(last_modified: @post.updated_at, etag: [@post, @post.comments.maximum(:updated_at)])
  end
```

Esto hará que el cache expire ya sea porque se actualizó el post (`last_modified: @post.updated_at`) o porque se creó o modificó un comentario (`etag: [@post, @post.comments.maximum(:updated_at)]`)

Si quisieramos cachear un búsqueda (colección de recursos), podríamos agregar el hash `params` dentro del array del etag para detectar cuando cambia un parámetro de búsqueda.