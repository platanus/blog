---
layout: post
title: Manejando versiones de modelos con Paper Trail
author: arturopuente
tags:
  - rails
  - paper-trail
  - activerecord
---

Uno de los problemas a los que frecuentemente nos enfrentamos es manejar diferentes versiones de un modelo, una forma de hacerlo es utilizando [la gema Paper Trail](https://github.com/airblade/paper_trail).

## Instalando Paper Trail

Lo primero es añadir la gema al Gemfile

```ruby
gem 'paper_trail', '~> 4.0.0'
```

Luego ejecutamos `bundle install` para instalarla. Luego ejecutamos este generador:

```bash
bin/rails generate paper_trail:install --with-changes
```

El flag `--with-changes` le indica al generador que queremos que nos ayude a manejar los diffs entre versiones.

Lo siguiente es ejecutar la migración:

```bash
bin/rake db:migrate
```

Esto nos va a generar una tabla de `versions`, que por defecto guarda todos los cambios de todos los modelos en los que queramos usar Paper Trail, y los identifica usando una combinación de `item_type` e `item_id`.

## Integrando Paper Trail en nuestra aplicación

El siguiente paso es incluirlo en nuestros modelos:

```ruby
class BlogPost < ActiveRecord::Base
  has_paper_trail
end
```

Para utilizarlo no necesitamos hacer nada en específico, automáticamente se van guardando versiones a medida que actualizamos nuestros modelo:

```ruby
post = BlogPost.new
post.title = "The post title"
post.content = "The post content"
post.save # Aquí se genera una versión nueva
post.versions.size #=> 1

post.title = "This is definitely not clickbait"
post.save # Aquí se genera otra versión
post.versions.size #=> 2

# Llamando a versions obtenemos un arreglo de las versiones
post.versions #=> [<PaperTrail::Version>, <PaperTrail::Version>]
```

#### Navegando entre versiones

```ruby

# Podemos instanciar una versión de esta forma:
first = post.versions.first.reify
# Esto nos devuelve un objeto de la misma clase con los atributos
# de la versión reificada, sin modificar el objeto original
first.title #=> "The post title"

# Para devolver nuestro modelo a la versión inmediatamente
# anterior podemos hacer esto:
post = post.last_version
post.save

# Podemos navegar entre las versiones utilizando previous_version
# y next_version. Como tenemos dos versiones, esto nos da el objeto
# en la primera versión que guardamos
post.previous_version
# Aquí devuelve nil porque estamos en la última versión del objeto
post.next_version
```

Con un modelo que tuviera más historial, podemos simplificar la tarea de andar buscando las versiones de esta forma:

```ruby
post = post.version_at(2.weeks.ago) # Aquí puede ir un timestamp
post.save
```

#### Encontrando las diferencias

Podemos llamar al método `changeset` de una versión para ver los cambios entre versiones:

```ruby
post = Post.create title: "The post title"
post.versions.last.changeset
# {
#   "title" => [nil, "The post title"],
#   "created_at" => [nil, 2015-09-12 03:45:10 UTC],
#   "updated_at" => [nil, 2015-09-12 03:45:10 UTC],
#   "id" => [nil, 1]
# }

# Como acabamos de crear el post, los atributos anteriores son nil
# pero al guardar otra versión veremos el diff
post.update_attributes title: "A different title"
post.versions.last.changeset
# {
#   "title" => ["The post title", "A different title"],
#   "updated_at" => [2015-09-12 03:45:10 UTC, 2015-09-12 03:45:29 UTC]
# }
```

## Configurando Paper Trail

#### Ignorando campos

Podemos pasarle `ignore` y una lista de campos que, si se actualizan, no generarán una versión nueva. Si se actualizan estos campos junto con otros campos que sí son trackeados, se va a generar una versión nueva, pero los campos ignorados no van a quedar reflejados en el historial de versiones.  

```ruby
class BlogPost < ActiveRecord::Base
  has_paper_trail, ignore: [:author_id]
end
```

#### Trackeando sólo ciertos campos

Esto tiene el efecto opuesto al ignore: sólo los campos que se pasen como en la lista generarán nuevas versiones de nuestro modelo y se verán reflejados en el historial.

```ruby
class BlogPost < ActiveRecord::Base
  has_paper_trail, only: [:title, :content]
end
```

#### Manejando eventos

También podemos filtrar los eventos que queramos utilizar, por defecto Paper Trail trackea `create`, `update` y `destroy`, pero es posible indicarle nuestros propios eventos.

```ruby
class BlogPost
  has_paper_trail, on: [:update, :destroy, :custom_event]
end
```

```ruby
post = BlogPost.find(1)
post.paper_trail_event = "update_title"
post.update_attributes title: "The Dark Knight"
post.versions.last.event #=> update_title
```

#### Limitando el número de versiones generadas

Para limitar el número de versiones trackeadas, podemos configurarlo así:

```ruby
PaperTrail.config.version_limit = 10
```

Para remover el límite, le asignamos `nil` a `version_limit` (este es el comportamiento por defecto).

#### Agregando metadata en las versiones

Le podemos pasar `meta` y un hash de atributos a Paper Trail para que guarde metadata adicional para cada versión:

```ruby
class BlogPost < ActiveRecord::Base
  has_paper_trail meta: { author_id: :author_id }
end
```

Esto nos sirve la buscar entre versiones, podemos obtener los cambios que ha realizado un usuario de esta forma:

```ruby
PaperTrail::Version.where(author_id: user.id)
```

Esto nos trae todos los cambios de este usuario, en la sección de configuración de una tabla diferente veremos cómo restringirlo de forma que nos devuelva solamente los objetos `BlogPost`.

#### Usando otra tabla para guardar las versiones

Si algún modelo en tiene muchos cambios es recomendable que las versiones de ese modelo se almacenen en una tabla separada para mejorar el rendimiento de la aplicación.

Lo primero es crear una subclase de `PaperTrail::Version`, donde indicamos el nombre de la tabla que queremos usar, además de poder cambiar algún comportamiento específico de estas versiones.

```ruby
class BlogPostVersion < PaperTrail::Version
  self.table_name = :blog_post_versions
end
```

Finalmente asignamos la clase a nuestro modelo:

```ruby
class BlogPost < ActiveRecord::Base
  has_paper_trail class_name: 'BlogPostVersion'
end
```

Ademas, si lo juntamos con el ejemplo de la metadata, podemos realizar un query directamente sobre esta clase para obtener sólamente los cambios en el modelo BlogPost que se han realizado:

```ruby
BlogPostVersion.where(author_id: user.id)
```

#### Asignando el usuario responsable de los cambios

Por defecto Paper Trail inyecta en `ApplicationController::Base` el método `user_for_paper_trail` que por defecto hace una llamada a `current_user`. Podemos modificar a quién se le asigna en el controlador base o proveer el método `user_for_paper_trail` en una clase diferente.

```ruby
class BlogPostContentProcessorService

  def update(user, post)
    @user = user
    post.update_attributes(content: process(content))
    version = post.versions.last
    version.whodunnit # El ID del user_for_paper_trail
  end

  def user_for_paper_trail
    @user
  end

  def process(content)
    # do something here
  end
end
```
