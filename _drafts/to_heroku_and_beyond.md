---
layout: post
title: "To heroku and beyond"
author: blackjid
tags:
    - potassium
    - rails
    - ruby
    - heroku
    - circleci
    - ci
---

En los últimos meses hemos estado trabajando para disminuir el tiempo necesario en la configuración y mantención de servidores para nuestras aplicaciones. Para esto se tomó la decisión de minimizar la candidad de servidores y externalizar parte de nuestro ya escaso "departamento" de devops.

El elegido fue [heroku][heroku], el que será nuestro PaaS donde de ahora en adelante, todos los nuevos proyectos serán publicados.

La idea es que esto quede plasmado en nuestra manera de trabajar y no tengamos dudas de como y donde se publica un projecto nuevo, para empujar este nuevo estándar le vamos duplicar la cantidad de potasio (K) en nuestra dieta con el release de Potassium 2.0

## Potassium 2.0

En el fondo, potassium sigue siendo lo mismo, un generador de aplicaciones rails customizado a las necesidades de platanus. Porque 2.0? Porque hay suficientes cambios como para dar el salto, asi podemos referirnos a potassium 2 cuando hablamos de soporte a heroku.

Algunos de los cambios mas importantes son:

- Dejamos de usar el archivo `.rbenv-vars` y ahora usamos `.env`. Parece ser solo un cambio de nombre, pero por detras el cambio real es que las variables ambientales nos son cargadas por rbenv, sino por la gema [dotenv][dotenv]
- En todos los proyectos se define un ambiente [staging][staging_env] el cual require el ambiente *production*, de esta manera podemos configurar cosas particulares en staging.
- Se agregó un nuevo comando para potassium `potassium install <recipe>` con este comando puedes agregar funcionalidad definida en potassium a un proyecto existente.
- El proyecto generado tiene todas las gemas y configuraciones necesarias para correr correctamente en heroku.

### CI/CD

Pero…. como se publica?? … bueno ahí esta la gran magia, no hay que hacer nada en particular.

Manteniendo nuestra relación estandar entre branch — stage, usaremos la [integración con github][heroku_github] de heroku y el soporte de automatic deploys. De esta manera la app staging sera publicada cada vez que el branch *master* cambia y la app production será publicada cada vez que el branch *production* cambia.

Sumado a esto, potassium deja configurado nuestro projecto para que podamos tener *continuous integration* usando el servicio de [Circle CI][circle], así en cada branch y PR se estarán corriendo los tests del proyecto. Esto permite que los automatic deploys solamente se ejecuten si los tests pasaron en el branch correspondiente.



## Con dudas todavía?

Ok, aqui hay una lista de los recursos a los que puedes acudir para saber como se debe hacer algo.

- En [La Guia][la_guia] de platanus hay una sección dedicada a [rails][la_guia_rails​] y [deployment][la_guia_deploy] para proyectos rails.
- En [readme][potassium_readme​] de potassium
- Se hizo un esfuerzo para que el `README.md` de la aplicación generada por potassium tenga información actualizada acerca del proyecto.

[heroku]: https://heroku.com
[dotenv​]: https://github.com/bkeepers/dotenv
[staging_env]: https://github.com/platanus/potassium/blob/master/lib/potassium/assets/config/environments/staging.rb
[heroku_github​]: https://devcenter.heroku.com/articles/github-integration
[circle​]: https://circleci.com
[la_guia]: http://la-guia.platan.us
[la_guia_deploy]: http://la-guia.platan.us/deployment/rails.html
[la_guia_rails​]: http://la-guia.platan.us/code/rails.html
[potassium_readme​]: https://github.com/platanus/potassium
