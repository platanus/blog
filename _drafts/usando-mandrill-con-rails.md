---
layout: post
title: Usando Mandrill desde Rails
authors:
  - emilioeduardob
  - bunzli
tags:
    - mandrill
    - ses
    - ruby
    - rails
---

## Introducción a Mandrill

En una aplicación rails, normalmente usaríamos Amazon SES para enviar los mails transaccionales. Muchas veces el cliente quisiera ver reportes de los envíos o también la posibilidad de editarlos. El objetivo de este post es explicar como enviar todos los mails de una aplicación rails a través del servicio mandrill.com.

### Api Keys

Puedes crear api keys con algunas opciones. Algo muy util es la opción de “test" para un api-key, que usa una dimensión paralela para probar todo sin mandar mails de verdad. Perfecto para desarrollo.

### Habilitar dominios

Puedes autorizar múltiples dominios. Fácilmente se siguen las instrucciones para además configurar correctamente el DKIM y SPF.


Se puede usar el API de Mandrill o las credenciales SMTP para enviar los mails. Nosotros abarcaremos el uso del API.

### Templates
Puedes crear tantos templates como la aplicación requiera. En cada template debes preocuparte de dejar **publicada** una versión que tenga al menos:

- Un contenido básico
- From Address
- From Name
- Subject

Si no defines esos valores, el mail no se mandará y es un poco invisible ese error.

### Templates Dinámicos

En Mandrill puedes usar dos tipos de lenguajes para templates. [Handlebars](http://blog.mandrill.com/handlebars-for-templates-and-dynamic-content.html) y el que se usa en [Mailchimp](https://mandrill.zendesk.com/hc/en-us/articles/205582487-How-do-I-use-merge-tags-to-add-dynamic-content-#mailchimp-merge-tags). El primero es más poderoso (condicionales, loops, etc…), pero tuvimos problemas cuando lo usamos con Mailchimp para exportar los templates a Mandrill.

Con Handlebars los templates se ven así:

```html
{% raw %}
Hola {{user_name}},

Acabas de comprar estos productos:

{{#products}}
  <ul>
    <li>{{this}}</li>
  </ul>
{{/products}}

{% endraw %}
```

### Exportando los templates de Mailchimp

Es súper básica la edición de los templates dentro de Mandrill. Es por eso que se pueden exportar los templates desde Mailchimp. Con esta [guía](https://mandrill.zendesk.com/hc/en-us/articles/205583097-How-do-I-add-a-MailChimp-template-to-my-Mandrill-account-) queda muy claro como hacerlo.

Ojo que no logramos usar handlebars desde acá!

### Api Logs

Existe una sección para ver todas las llamadas al API, con error y con éxito.

## Integración con Rails via SMTP

Mandrill se puede utilizar como un servidor SMTP común y corriente, configurando `action_mailer` como en el siguiente ejemplo

```ruby
config.action_mailer.delivery_method = :smtp

config.action_mailer.smtp_settings = {
   address: ENV.fetch("SMTP_SERVER"), # smtp.mandrillapp.com
   authentication: :plain,
   enable_starttls_auto: true,
   password: ENV.fetch("MANDRILL_APIKEY"),
   port: "587",
   user_name: ENV.fetch("MANDRILL_USERNAME") # login email en mandrill
 }

```

Con eso estamos listos para usar los Mailers existentes de Rails y enviarlos con Mandrill.

Pero como queremos utilizar **MailChimp** para gerenciar los templates de cada tipo de email, no enviaremos emails por SMTP, sino usando la `API HTTP` de Mandrill


## Integración con Rails usando API Http

### Setup inicial

- Agregar la gema `mandrill-api` en el `Gemfile`
- Setear las variables en `.rbenv-vars`
```
MANDRILL_APIKEY=XXX
```

### Creando el MandrillMailer

Este módulo será la base para mandar emails usando los templates de Mandrill desde otros Mailers.

``` ruby
require "mandrill"

module MandrillMailer
  def send_mail(to, template_name, attributes)
    return if Rails.env.test?
    mandrill = Mandrill::API.new(ENV["SMTP_PASSWORD"])

    merge_vars = attributes.map do |key, value|
      { name: key, content: value }
    end

    to = [to] unless to.is_a?(Array)
    recipients = to.map { |email|  { "email" => email, "type" => "to" } }

    message = {
     "global_merge_vars" => merge_vars,
     "to"=> recipients
     }
    results = mandrill.messages.send_template template_name, [], message
    if results.any?{|result| !result["reject_reason"].nil? }
      Rails.logger.info "Couldn't send all emails: #{results}"
    end

  rescue Mandrill::Error => e
    # Mandrill errors are thrown as exceptions
    puts "A mandrill error occurred: #{e.class} - #{e.message}"
    # A mandrill error occurred: Mandrill::UnknownSubaccountError - No subaccount exists with the id 'customer-123'
    raise

  end

end
```

### Utilizando un Mailer normal

Podemos utilizar un nuevo Mailer o crear uno y debemos incluir el módulo en el mailer como en este ejemplo:

```ruby
class PetsMailer < ActionMailer::Base
  include MandrillMailer

  def for_adoption(pet_shop, cats)

    # build a list of cats with only the desired data to pass
    list = cats.map do |cat|
      {
        name: cat.name,
        age: cat.age
      }
    end

    # all template vars
    template_vars = {
      "cats" => list,
      "shop_name" => pet_shop.name
    }

    send_mail(pet_shop.email, "adopt-a-cat-template", template_vars)
  end

```

Se puede ver que no estamos utilizando el método `mail` de ActionMailer sino `send_mail`. Este método recibe 3 parametros.

1. **to:** Puede ser una dirección de mail(string) o un arreglo de direcciones
2. **template:** El nombre del template(**slug**) a utilizar en el envío
3. **template_vars:** Este es un diccionario(Hash) con las variables necesarias en el template. En el ejemplo. `cats` es un arreglo con hashes y `shop_name` es solo un string

### Utilizando en Devise Mailer

Para utilizar Mandrill con Devise, necesitamos crear un Mailer que herede de `Devise::Mailer` y configurarlo en Devise

```ruby
# initializers/devise.rb
config.mailer = 'MyDeviseMailer'
```

Tenemos que reimplementar cada tipo de mail que queramos utilizar con Mandrill, en el ejemplo la recuperación de password y confirmación de cuenta.
Si es que estuviera habilitado otro tipo de mail de devise, no pasaría por Mandrill (Como ser `send_unlock_instructions`) y se enviaría por SMTP directamente.

``` ruby
class MyDeviseMailer < Devise::Mailer
  include MandrillMailer
  helper :application

  def reset_password_instructions(record, token, opts={})
    template_vars = {
      "user_name" => record.display_name,
      "reset_link" => edit_user_password_url(record, reset_password_token: token)
    }

    send_mail(record.email, "recover-password-slug", template_vars)
  end

  def confirmation_instructions(record, token, opts={})
    template_vars = {
      "user_name" => record.display_name,
      "confirm_link" => new_user_confirmation_url(record, confirmation_token: token)
    }

    send_mail(record.email, "confirm-account-slug", template_vars)
  end

end

```
