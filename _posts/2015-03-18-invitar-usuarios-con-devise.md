---
layout: post
title: Invitar usuarios con Devise
author: ldlsegovia
tags:
    - rails
    - active admin
    - devise
redirect_from: rails/active admin/devise/2015/03/18/invitar-usuarios-con-devise.html
---

Muchas veces, nos toca realizar aplicaciones que no permiten que un usuario se registre libremente. Es decir, se necesita de un administrador (o algún usuario de mayor jerarquía) que cree una cuenta para ese nuevo usuario. Cuando esto ocurre, se nos presenta el problema de cómo entregar a esa persona las credenciales para que pueda acceder. Pensando alrededor de este asunto, ideamos esta solución que presento a continuación.

1. El **administrador** entra en la aplicación.
1. El **administrador** crea un nuevo usuario utilizando únicamente su Email.
1. El **usuario**, recibe un mail de invitación con un link que lo redirige a un formulario para ingresar su contraseña.
1. El **usuario** ingresa su contraseña y confirmación.
1. El **usuario** es logueado automáticamente en la aplicación si la contraseña es válida. Caso contrario, se le presentará un mensaje de error.

Googleando un poco, dimos con una gema que resuelve exactamente este problema. La gema en cuestión se llama [Devise Invitable](https://github.com/scambra/devise_invitable) y como su nombre indica, trabaja como una extensión de [Devise](https://github.com/plataformatec/devise). A continuación explicaré brevemente el uso de esta gema y luego propondré una forma de integrarla con [Active Admin](https://github.com/activeadmin/activeadmin) ya qué, comunmente en Platanus, utilizamos este framework de administración.

## Instalación y uso de Devise Invitable

Agregar Devise al `Gemfile`

```ruby
gem 'devise'
```
Correr el generador de devise

```bash
$ rails generate devise:install
```
Utilizar devise con algún modelo (típicamente `User`)

```bash
$ rails generate devise User
```
Esto generará un modelo `User` con la siguiente estructura:

```ruby
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
end
```
Luego de correr migraciones, estaremos listos para autenticar a nuestro usuario de tipo `User`.
Ahora que tenemos devise funcionando con uno de los modelos de nuestra aplicación (`User` en este caso), podremos invitar usuarios siguiendo los pasos a continuación:

Agregar Devise Invitable al `Gemfile`

```ruby
gem 'devise_invitable', '~> 1.3.4'
```

Correr el instalador.

```bash
rails generate devise_invitable:install
```
Esto modificará el initializer `devise.rb`con configuración propia de la gema.

Usar Devise Invitable con nuestro modelos `User`

```bash
rails generate devise_invitable User
```

Esto abrirá el modelo `User` y agregará a la configuración de devise para ese modelo, la opción `:invitable`. También creará la migración que agregue todo lo necesario para trabajar con esta gema.

```ruby
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :invitable, :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable
end
```
> Quizás quieras remover la opción `:registerable` si el usuario sólo puede registrarse a través de una invitación.

Una vez hecho lo anterior, sólo resta correr migraciones y nuestro modelo `User` estará listo para trabajar con invitaciones.

Para enviar una invitación se debe, desde algún lugar accesible para el administrador (o usuario de mayor jerarquía), ejecutar el siguiente código:

```ruby
User.invite!(:email => "new_user@platan.us")
```
Esto enviará al usuario, un email con un link a un formulario para que pueda elegir su contraseña. Una vez ingresada la clave, el usuario será redirigido dentro de la aplicación.

## Integración con Active Admin

Muchas veces se da la situación en que el administrador general tiene que crear administradores con menores privilegios. Esto quiere decir que:

* El nuevo administrador deberá ser redirigido a un formulario para la elección de clave **dentro de Active Admin** (con vistas y estilos de Active Admin) luego de recibir el mail con la invitación.
* El nuevo administrador deberá ser redirigido **dentro de la zona de administración** luego de ingresar su clave.

Para lograr esto, una opción es:

Dentro del initializer de Active Admin (`active_admin.rb`) agregar:

```ruby
module ActiveAdmin
  module Devise
    class << self
      alias_method :old_controllers, :controllers
      def controllers
        old_controllers.merge({invitations: "active_admin/devise/invitations"})
      end
      alias_method :old_controllers_for_filters, :controllers_for_filters
      def controllers_for_filters
        old_controllers_for_filters + [InvitationsController]
      end
    end
    class InvitationsController < ::Devise::InvitationsController
      include ::ActiveAdmin::Devise::Controller
    end
  end
end
```
para crear un controlador de invitaciones que herede la funcionalidad que Active Admin agrega a todos los controladores de Devise.

Luego se debe correr el generador de vistas de Devise Invitable con el fin de modificar las originales, adecuandolas a la definición de estilos de Active Admin.

```bash
rails g devise_invitable:views
```

Por ejemplo, podemos modificar esta vista `/example_app/app/views/devise/invitations/edit.html.erb`

```erb
<h2><%= t 'devise.invitations.edit.header' %></h2>

<%= form_for resource, :as => resource_name, :url => invitation_path(resource_name), :html => { :method => :put } do |f| %>
  <%= devise_error_messages! %>
  <%= f.hidden_field :invitation_token %>

  <p><%= f.label :password %><br />
  <%= f.password_field :password %></p>

  <p><%= f.label :password_confirmation %><br />
  <%= f.password_field :password_confirmation %></p>

  <p><%= f.submit t("devise.invitations.edit.submit_button") %></p>
<% end %>
```

y dejarla así:

```erb
<div id="login">
  <h2><%= t 'devise.invitations.edit.header' %></h2>

  <%= active_admin_form_for(resource, as: resource_name, url: invitation_path(resource_name), html: { method: :put }) do |f|
    f.inputs do
      f.input :password
      f.input :password_confirmation
      f.input :invitation_token, as: :hidden, input_html: { value: resource.invitation_token }
    end
    f.actions do
      f.action :submit, label: t('devise.invitations.edit.submit_button'), button_html: { value: t('devise.invitations.edit.submit_button') }
    end
  end
  %>
</div>
```

y eso es todo!

> Se debe tener en cuenta que si tenemos dos modelos "invitables" (uno redirigido al Administrador y otro a la App), deberemos dejar aquí `/example_app/app/views/devise/invitations` las vistas modificadas para trabajar con Active Admin y correr el generador nuevamente, para crear vistas en otra ubicación para utilizar con el modelo que debe ser redirigido a la aplicación.

