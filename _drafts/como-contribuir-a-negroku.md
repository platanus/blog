---
title: "Cómo contribuir a Negroku"
layout: post
author:
    - arturopuente
categories:
    - negroku
    - devops
    - openbanana
---

Alguna vez te has preguntado cómo Negroku realiza alguna tarea o quieres que automatice un proceso que te parece repetitivo, pero cuando se lo pides a @blackjid está con 20 tareas pendientes? Bueno, ahora vamos a dar un repaso ligero a cómo está hecho Negroku para que tú también puedas ayudar a mejorarlo!

## Primeros pasos

Empecemos por dar un repaso a la arquitectura general del proyecto, dentro de la carpeta `lib`:

```ruby
+-- negroku/
|  +-- cli/
|  +-- formatters/
|  +-- helpers/
|  +-- locales/
|  +-- tasks/
|  +-- templates/
|  +-- cli.rb
|  +-- deploy.rb
|  +-- helpers.rb
|  +-- i18n.rb
|  +-- version.rb
+-- negroku.rb
```

Nos interesa un archivo muy importante: `deploy.rb`.

### El despliegue

Gran parte de la funcionalidad (y la forma más fácil para poder extenderla o modificarla) se encuentra dentro de rake tasks que son llamadas desde el archivo de despliegue mediante `load_task`.

```ruby
require 'negroku/helpers'

# Base configuration
namespace :load do
  task :defaults do

    set :scm, :git

    set :format, :pretty
    set :log_level, :debug
    set :pty, true

    set :keep_releases, 5
  end
end

# Load Negroku tasks
load_task "negroku"
load_task "rbenv"     if was_required? 'capistrano/rbenv'
load_task "nodenv"    if was_required? 'capistrano/nodenv'
load_task "bower"     if was_required? 'capistrano/bower'
load_task "bundler"   if was_required? 'capistrano/bundler'
load_task "rails"     if was_required? 'capistrano/rails'
load_task "nginx"     if was_required? 'capistrano/nginx'
load_task "unicorn"   if was_required? 'capistrano3/unicorn'
# Si quisiéramos añadir soporte para otro servidor de aplicaciones, podríamos añadir una línea como esta y tendríamos en `lib/negroku/tasks/puma.rake` los rake tasks que deseamos para manejar Puma.
load_task "puma"      if was_required? "capistrano3/puma"
load_task "delayed_job"   if was_required? 'capistrano/delayed-job'
load_task "whenever"  if was_required? 'whenever/capistrano'

load_task "log"
```

Otra tarea bastante común como añadir una variable de rbenv al servidor también llama a un task dentro de `rbenv.rake`:

```ruby
namespace :rbenv do
  namespace :vars do
    desc "Show current environmental variables"
    task :show do
      on release_roles :app do
        within current_path do
          execute :rbenv, 'vars'
        end
      end
    end

    desc "Add environmental variables in the form VAR=value"
    task :add, :variable do |t, args|

      vars = [args.variable] + args.extras
      # Aquí se crea el archivo de no existir en el deploy, y para cada valor recibido, se llama a `build_add_var_cmd`, que lo que hace es verificar si la llave que le hemos pasado existe, si es así, reemplaza el valor, de lo contrario lo agrega al archivo.
      on release_roles :app do
        within shared_path do
          unless test "[ ! -f .rbenv-vars ]"
            execute :touch, ".rbenv-vars"
          end
          vars.compact.each do |var|
            key, value = var.split('=')
            cmd = build_add_var_cmd("#{shared_path}/.rbenv-vars", key, value)
            execute cmd
          end
        end
      end

    end

    desc "Remove environmental variable"
    task :remove, [:key] do |t, args|
      on release_roles :app do
        within shared_path do
          execute :sed, "-i", "/^#{args[:key]}=/d", ".rbenv-vars"
        end
      end
    end

  end
end

```

Esta es la función que se llama para agregar una variable de entorno.

```bash
# helper to build the add VAR cmd
def build_add_var_cmd(vars_file, key, value)
  puts "#{vars_file} #{key} #{value}"
  cmd = "if awk < #{vars_file} -F= '{print $1}' | grep --quiet -w #{key}; then "
  cmd += "sed -i 's/^#{key}=.*/#{key}=#{value.gsub("\/", "\\/")}/g' #{vars_file};"
  cmd += "else echo '#{key}=#{value}' >> #{vars_file};"
  cmd += "fi"
  cmd
end
```

