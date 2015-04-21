---
title: "Usando Angular Auth Lib con Simple Token Authentication Gem"
layout: post
authors:
    - emilioeduardob
    - ldlsegovia
tags:
    - rails
    - authentication
    - restmod
    - angular
---

Debido a que en cada proyecto que iniciamos, donde típicamente tenemos una aplicación cliente construída con angular que se comunica con una API Rails, utilizamos una estrategia de autenticación diferente, surgió la necesidad de implementar un estandar para resolver este problema y no tener que improvisar soluciones en el momento.

Investigando decidimos...

* Para la **API**: utilizar la gema [Simple Token Authentication](https://github.com/gonzalo-bulnes/simple_token_authentication) que permite la autenticación via token.

* Para la **Aplicación cliente**: construímos, con [Angular Restmod](https://github.com/platanus/angular-restmod) como única dependencia, la libreía [Angular Auth](https://github.com/platanus/angular-auth) para comunicarnos fácilmente con la API.

A continuación, explicaremos como configurar la gema y la librería y luego mostraremos un ejemplo de uso.

## Configuración

### Simple Token Authorization Gem

Obviamente, el README de la gema tiene información más completa pero, básicamente para funcionar en una app Rails con Devise instalado necesitamos:

Agregar al Gemfile:

```ruby
gem 'simple_token_authentication'
```

En el modelo de devise que tengamos (por ejemplo User), agregamos la funcionalidad de la gema así:

```ruby
class User < ActiveRecord::Base

  acts_as_token_authenticatable

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :invitable, :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable,
         :lockable

  # ...
end
```

Suponiendo que tenemos un API Base controller, agregamos el helper de la librería:

```ruby
class ApiBaseController < ActionController::Base
  # ...

  acts_as_token_authentication_handler_for User

  # un monton de codigo ...
end
```

Esto permite que este controller y sus hijos, puedan realizar autenticación con Email y Token. La gema espera recibir los  headers `X-User-Email` y `X-User-token`.


### Aungular Auth

Para instalar la liberaría, en el cliente JS:

```shell
$ bower install platanus-angular-auth --save
```

Agregamos el módulo como dependencia Angular

```javascript
angular.module('yourapp', ['PlAuth']);
```

## Ejemplo

Supongamos que queremos una app que permita crear mis Bandas favoritas. Para eso necesitaríamos una API Rails utilizando la gema con los siguientes endpoints:

* `POST /api/sessions` : Crea una nueva sesion y debe devolver un JSON con por lo mínimo estos datos `{'uid': 'alf@melmac.com', 'token': 'XX'}`
* `POST /api/bands` : Crea una nueva banda (Ruta autenticada)

Y una App Ionic con un formulario para crear bandas y enviarlas a la API.
Antes que nada, necesitaremos un modelo Restmod `Session` con el cual crear la sesión de la siguiente manera:

```javascript
var loginForm = {..};
Session.$create(loginForm).$then(function(data) {
  AuthSrv.store(data);
});
```

Esto persiste la sesión del lado del cliente.
Una vez hecho esto, podremos, en cualquier modelo de Restmod, agregar el mixin `HttpAuth` para autorizar los requests de la siguiente manera:

```javascript
var Band = restmod.model('bands').mix('HttpAuth');
var bandData = {..};
vm.bands = Band.$create(bandData);
```

Esto haría un POST a `/api/bands` con los headers `X-User-Email` y `X-User-Token` creando mi banda favorita.
