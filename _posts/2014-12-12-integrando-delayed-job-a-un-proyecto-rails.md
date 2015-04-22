---
title: Integrando Delayed Job gem a un proyecto Rails
authors:
    - arturopuente
    - ldlsegovia
layout: post
tags:
    - rails
    - gems
redirect_from: Rails/Gems/2014/12/12/integrando-delayed-job-a-un-proyecto-rails.html
---

[Delayed Job](https://github.com/collectiveidea/delayed_job) es una gema que permite ejecutar tareas "pesadas" en background de forma asíncrona. Para no ser redundantes con el [README](https://github.com/collectiveidea/delayed_job/blob/master/README.md) de la gema, mostraremos brevemente la instalación y uso (Rails 4) y luego haremos hincapié en lo más interesante de la gema.

## Instalación

Agregar al `Gemfile`:

```ruby
gem 'delayed_job_active_record'
gem 'daemons'
```

La gema `daemons` es utilizada por el ejecutable de delayed_job encargado de procesar las tareas pendientes, sin embargo no es un requisito obligatorio. De no incluirla, no podremos usar el ejecutable de delayed_job, las tareas serán procesadas normalmente y nuestro código se mantendrá igual.

Instalar

```bash
$ bundle install
```

Crear tabla donde la gema persiste las tareas en cola:

```bash
$ rails generate delayed_job:active_record
$ rake db:migrate
```

## Uso

Básicamente hay dos formas de mandar una tarea a background:

1. Llamando al método `delay`, antes de llamar al método que ejecuta la tarea. Por ej. si tengo el método:

    ```ruby
    @user.exec_instance_method
    User.exec_class_method
    ```

    para mandarlo a background necesito hacer:


    ```ruby
    @user.delay.exec_instance_method
    User.delay.exec_class_method
    ```

2. Si nuestro método siempre debe ser ejecutado en background, en vez de llamar a `delay` cada vez, podemos definir nuestro método de la siguiente manera:

    ```ruby
    class User
      def exec_instance_method
        # long running method
      end
      handle_asynchronously :exec_instance_method
    end

    user = User.new
    user.exec_instance_method
    ```

También podemos definir un tiempo de espera antes de ejecutar el método de esta forma:

```ruby
class UserMailer
  def send_email
    # email user for confirmation
  end

  handle_asynchronously :send_email, run_at: Proc.new { 10.minutes.from_now }
end

UserMailer.new.send_email
```

Una vez que hayamos definido métodos para ser ejecutados en el background, debemos levantar los workers desde la línea de comandos:

```bash
$ RAILS_ENV=production bin/delayed_job -n 2 start
```

De esta forma se empezarán a procesar las tareas pendientes. El flag `-n` sirve para especificar el número de workers que serán creados. Si sólo queremos un worker, podemos omitirla.

Finalmente, para detener los workers debemos utilizar el siguiente comando:

```bash
$ RAILS_ENV=production bin/delayed_job stop
```

## Funcionamiento

Cada vez que creamos una tarea en delayed jobs, lo que hacemos es crear una entrada en la tabla `delayed_jobs`
Si tenemos la gema `daemons` instalada, un demonio revisará, cada cierto tiempo, esta tabla y ejecutará cada una de las tareas cuando corresponda. Si no tenemos la gema, se generará la entrada pero la tarea se ejecutará inmediatamente. Tal funcionamiento, probablemente es deseable en desarrollo, pero no en producción.

La tabla tiene varios atributos interesantes de comentar:

- **priority** es un número que permite escalar en la cola y, como dice el nombre del atributo, tener prioridad por sobre otras tareas. Mientras menor sea el entero, mayor prioridad.

- **handler** es un atributo de tipo `text` que almacena en forma de `YAML` la definición del método que tiene que ejecutar. Por ej. si tengo el método:

    ```ruby
    def self.say_hello _user
      puts "Hello #{_user.name}!"
    end
    ```

    y lo ejecuto de la siguiente manera:

    ```ruby
      user = User.create! name: "Pepe"
      User.delay.say_hello user
    ```

    se generará una entrada en la tabla con el atributo **handle** conteniendo:

    ```yaml
    --- !ruby/object:Delayed::PerformableMethod
    object: !ruby/class 'User'
    method_name: :say_hello
    args:
    - !ruby/ActiveRecord:User
      attributes:
        id: 1
        name: Pepe
        created_at: 2014-12-12 14:38:17.083630000 Z
        updated_at: 2014-12-12 14:38:17.083630000 Z

    ```
    Como se puede ver, este atributo contiene toda la información necesaria para correr el método `say_hello` de la clase `User` con la instancia (parámetro) del `User` *Pepe* en cualquier momento.

- **run_at** contendrá el `DateTime` en que la tarea se ejecutó exitosamente. Se debe tener en cuenta que si tenemos la gema [daemons](https://github.com/ghazel/daemons) instalada, las tareas completadas exitosamente será borradas de la tabla.

- **failed_at** contendrá  el `DateTime` en que una tarea falló en su ejecución. Si falla, se reintentará ejecutar la tarea nuevamente luego. Las tareas fallidas, no se eliminarán de la tabla hasta que se llegue al número máximo de reintentos (25 es el default)

- **attempts** es un entero que almacena el número de intentos que dejayed jobs intentó ejecutar una tarea en particular. La gema reintentará ejecutar en 5 segundos + N**4, donde N es el número de intentos realizados.

- **last_error** almacena detalle del error que se produjo cuando una tarea no se puedo ejecutar.

## Colas

Delayed job también nos permite definir colas para segmentar tareas de la siguiente manera:

```ruby
class UserMailer
  def send_welcome_email
    # welcome details
  end

  def send_confirmation_email
    # confirmation details
  end

  handle_asynchronously :send_welcome_email, queue: 'mailers'
end

user = UserMailer.new
user.send_welcome_email
user.delay(queue: 'mailers').send_confirmation_email
```

Y los ejecutamos de la siguiente manera

```bash
RAILS_ENV=production bin/delayed_job --queue=mailers start
```

Si queremos ejecutar más colas con un mismo worker tenemos que separarlas mediante comas:

```bash
RAILS_ENV=production bin/delayed_job --queue=mailers,tasks,myqueue start
```

## Integración con Capistrano

Para una "painless" integración con Capistrano, utilizare  gema: [capistrano3-delayed-job](https://github.com/platanus/capistrano3-delayed-job)
