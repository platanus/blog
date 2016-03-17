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

Pry y Byebug son dos herramientas que nos sirven bastante para desarrollar aplicaciones de Ruby: [Pry](https://github.com/pry/pry) nació como un reemplazo de IRB (el intérprete de Ruby), mientras que [Byebug](https://github.com/deivid-rodriguez/byebug)	 empezó siendo un sucesor espiritual de la gema `debugger` debido a que esta no funciona con Ruby 2.0.

La gema de `pry-byebug` añade los comandos de debugging y comportamiento de Byebug a Pry, permitiéndonos usar los poderes (introspección, historial de comandos, navegación por nuestro codebase, el de librerías y el de Ruby en sí, etc) que ofrece este último.

## Instalación

Lo primero es añadir la gema a nuestro `Gemfile` (esta tiene como dependencias a `pry` y `byebug`):

```ruby
group :development, :test do
  gem "pry-byebug"
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

Podemos devolver el REPL a un estado limpio de breakpoints usando el comando `reset`. Si hemos hecho cambios en nuestro código, `reload!` actualizará el código que se muestra en el REPl también.

## Navegando el stack

Cada llamada que estamos haciendo representa un `frame` o nivel del stack, podemos verlas mediante el comando `pry-backtrace`, pero presenta el stack completo sin números de frames, por eso añadimos un plugin de `pry-stack-explorer` que nos ayudará con esto.

```ruby
group :development, :test do
  gem "pry-byebug"
  gem "pry-stack_explorer"
end
```

Al ejectuar `show-stack` obtenemos esto:

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

## Navegando por nuestra aplicación

Un comando que es muy útil para revisar el código de la aplicación es `show-method`, por ejemplo:

```ruby
show-method User.fetch_user_posts
```

Nos muestra más información sobre el método y su contexto, esto también se puede usar con los métodos de otras librerías y de Ruby mismo (incluso con los métodos nativos de C!) :

```ruby
From: /Users/arturo/dev/projects/platanus/blog-test-app/app/models/user.rb @ line 9:
Owner: <Class:User(id: integer, email: string, encrypted_password: string, reset_password_token: string, reset_password_sent_at: datetime, remember_created_at: datetime, sign_in_count: integer, current_sign_in_at: datetime, last_sign_in_at: datetime, current_sign_in_ip: string, last_sign_in_ip: string, created_at: datetime, updated_at: datetime)>
Visibility: public
Number of lines: 5

def self.fetch_user_posts
  self.all.map do |user|
    user.fetch_categorized_posts
  end
end
```

Para ir navegando entre clases usamos `cd`, podemos ir a la clase `User` ejecutando:

`cd User`

Y desde ahí podemos obtener la información de los métodos que ha definido y heredado utilizando `ls`

```
[24] pry(User):1> ls
constants:
  ActiveRecord_AssociationRelation           ActiveRecord_Relation
  ActiveRecord_Associations_CollectionProxy  GeneratedAssociationMethods
Object.methods: yaml_tag
ActiveModel::Naming#methods: model_name
ActiveSupport::Benchmarkable#methods: benchmark
ActiveSupport::DescendantsTracker#methods: descendants  direct_descendants
ActiveRecord::ConnectionHandling#methods:
  clear_active_connections!      connected?         connection_id=        remove_connection
  clear_all_connections!         connection         connection_pool       retrieve_connection
  clear_cache!                   connection_config  establish_connection
  clear_reloadable_connections!  connection_id      mysql2_connection
ActiveRecord::QueryCache::ClassMethods#methods: cache  uncached
ActiveRecord::Querying#methods:
  any?          destroy_all  find_in_batches        forty_two   joins    offset      second!  update
  average       distinct     find_or_create_by      forty_two!  last     order       select   update_all
  calculate     eager_load   find_or_create_by!     fourth      last!    pluck       sum      where
  count         except       find_or_initialize_by  fourth!     limit    preload     take
  count_by_sql  exists?      first                  from        lock     readonly    take!
  create_with   fifth        first!                 group       many?    references  third
  delete        fifth!       first_or_create        having      maximum  reorder     third!
  delete_all    find_by_sql  first_or_create!       ids         minimum  rewhere     uniq
  destroy       find_each    first_or_initialize    includes    none     second      unscope
ActiveModel::Translation#methods: human_attribute_name
ActiveRecord::Translation#methods: i18n_scope  lookup_ancestors
ActiveRecord::DynamicMatchers#methods: respond_to?
...
```

E investigar las variables locales y de clase que esta clase maneja con `ls -i`:

```
[25] pry(User):1> ls -i
instance variables:
  @__reflections                    @columns_hash                   @persistable_attribute_names
  @arel_engine                      @content_columns                @primary_key
  @arel_table                       @default_attributes             @quoted_primary_key
  @attribute_method_matchers_cache  @finder_needs_type_condition    @quoted_table_name
  @attribute_methods_generated      @generated_association_methods  @relation
  @attributes_builder               @generated_attribute_methods    @relation_delegate_cache
  @column_names                     @inheritance_column             @sequence_name
  @column_types                     @locking_column                 @table_name
  @columns                          @parent_name
class variables:
  @@configurations               @@maintain_test_schema              @@time_zone_aware_attributes
  @@default_timezone             @@primary_key_prefix_type           @@timestamped_migrations
  @@dump_schema_after_migration  @@raise_in_transactional_callbacks
  @@logger                       @@schema_format
```

## Editando código desde Pry

Lo primero es configurar el editor que queremos usar, hay que agregar la siguiente línea al archivo `.pryrc`

```ruby
Pry.config.editor = "vim"
```

Ahora, al momento de detener la ejecución podemos editar el frame actual utilizando:

```bash
edit -c
```

O usar la sintaxis de `.` y `#` para pasar métodos de clase e instancia como argumento de edit:

```bash
edit User
edit User.fetch_user_posts
edit Posts#fetch_external_links
```

Eso nos abrirá el editor con la clase o método que deseamos.
