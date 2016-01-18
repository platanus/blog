---
layout: post
title: Resolviendo errores con pry y byebug
author: arturopuente
tags:
  - rails
  - testing
  - debugging
  - pry
  - byebug
---

## Instalación

Lo primero es añadir la gema a nuestro `Gemfile` (esta tiene como dependencias a `pry` y `byebug`):

```ruby
group :development, :test do
  gem "pry-byebug"
  gem "pry-stack_explorer"
end
```

## Deteniendo la ejecución

Vamos a empezar trazando el flujo de una aplicación:

1) Tenemos un controlador `HomeController` que recibe una llamada a index, llama al método `User.fetch_user_posts` y renderiza los datos en JSON.

2) El método `User.fetch_user_posts` itera sobre todos los usuarios y llama al método `fetch_categorized_posts`.

3) El método `fetch_categorized_posts` se encarga de iterar sobre los posts del usuario, y si no tiene una categoría, asignarle uncategorized, para luego devolver todos los posts. Este método se ve así inicialmente:

```ruby
def fetch_categorized_posts
  self.posts.map do |post|
    if post.tags.nil?
      post.tags = "uncategorized"
    end
    post
  end
end
```

Esto nos devuelve el JSON desde el controlador correctamente, pero al entrar a una consola de Rails e inspeccionar un post vemos esto:

```ruby
<Post:0x007f8d348a0570
 id: 1,
 user_id: 1,
 title: "First post",
 content: "Test content",
 tags: nil>
```

Los tags no se han guardado, así que vamos a detener la ejecución en el momento en el que asignamos los tags:

```ruby
def fetch_categorized_posts
  self.posts.map do |post|
    binding.pry
    if post.tags.nil?
      post.tags = "uncategorized"
    end
    post
  end
end
```

Al detenerse la ejecución vamos a ver la interfaz de pry:

```ruby
   15: def fetch_categorized_posts
   16:   self.posts.map do |post|
   17:     binding.pry
=> 18:     if post.tags.nil?
   19:       post.tags = "uncategorized"
   20:     end
   21:     post
   22:   end
   23: end

[1] pry(<User>)>
```

Aquí podemos comprobar que llamando a `post.tags.nil?` el resultado es `true`, por lo tanto debe caer en la condición de la línea 19. Para ver el estado del post en la línea 21 podemos ejecutar el siguiente comando:

`break 21`

Lo que va a añadir un breakpoint adicional en la línea 21, continuamos la ejecución con el comando `continue`:

```ruby
   15: def fetch_categorized_posts
   16:   self.posts.map do |post|
   17:     binding.pry
   18:     if post.tags.nil?
   19:       post.tags = "uncategorized"
   20:     end
=> 21:     post
   22:   end
   23: end

[1] pry(<User>)>
```

Aquí podemos ver que llamando `post.tags` obtenemos uncategorized, qué pasa si buscamos aquí el post por el ID? `Post.find(post.id).tags` nos devuelve nil.

La respuesta es simple, no estamos persistiendo los tags, sólo asignándolos a las instancias que traemos, la forma de arreglarlo es muy simple:

```ruby
def fetch_categorized_posts
  self.posts.map do |post|
    if post.tags.nil?
      post.update_attributes tags: "uncategorized"
    end
    post
  end
end
```

Podemos devolver el REPL a un estado limpio de breakpoints usando el comando `reset`. Si hemos hecho cambios en nuestro código, `reload!` actualizará el código que se muestra en el REPl también

## Navegando el stack

Cada llamada que estamos haciendo representa un `frame` o nivel del stack, podemos verlas mediante el comando `pry-backtrace`, pero presenta el stack completo sin números de frames, por eso añadimos un plugin de Pry que nos ayudará con esto. Al ejectuar `show-stack` obtenemos esto:

```
Showing all accessible frames in stack (88 in total):
--
=> #0  fetch_categorized_posts <User#fetch_categorized_posts()>
   #1 [method]  fetch_categorized_posts <User#fetch_categorized_posts()>
   #2 [block]   block in fetch_user_posts <User.fetch_user_posts()>
   #3 [method]  map <ActiveRecord::Delegation#map(*args, &block)>
   #4 [method]  fetch_user_posts <User.fetch_user_posts()>
   #5 [method]  index <HomeController#index()>
   #6 [method]  send_action <ActionController::ImplicitRender#send_action(method, *args)>
   #7 [method]  process_action <AbstractController::Base#process_action(method_name, *args)>
   #8 [method]  process_action <ActionController::Rendering#process_action(*arg1)>
   #9 [block]   block in process_action <AbstractController::Callbacks#process_action(*args)>
   #10 [method]  call <ActiveSupport::Callbacks::Filters::End#call(env)>
   #11 [block]   block (2 levels) in compile <ActiveSupport::Callbacks::CallbackChain#compile()>
   #12 [method]  call <ActiveSupport::Callbacks::CallbackSequence#call(*args)>
   #13 [method]  __run_callbacks__ <ActiveSupport::Callbacks#__run_callbacks__(callbacks, &block)>
   #14 [method]  _run_process_action_callbacks <ActionController::Base#_run_process_action_callbacks(&block)>
   #15 [method]  run_callbacks <ActiveSupport::Callbacks#run_callbacks(kind, &block)>
   #16 [method]  process_action <AbstractController::Callbacks#process_action(*args)>
   #17 [method]  process_action <ActionController::Rescue#process_action(*args)>
   ...
```

Los primeros frames son los más interesantes para nosotros porque son los métodos que hemos definido. Podemos navegar entre frames utilizando el comando frame y como argumento el número del frame.

Por ejemplo, para ir al controlador podríamos ejecutar `frame 5`, o para ir al método `User.fetch_user_posts` podemos ejecutar `frame 4`.

Otra forma de navegar entre frames es con los métodos `up` y `down`. Si empezamos en el frame 0, `up` nos lleva al frame superior, en este caso el 1. Luego, para bajar a un frame inferior, `down` nos llevaría del frame 5 al 4.
