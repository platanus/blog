---
layout: post
title: Personalizando la interfaz de Active Admin
author: arturopuente
tags:
  - rails
  - active-admin
  - ui
---

La interfaz inicial de ActiveAdmin, al ser genérico (y pensando originalmente sólo para ser un CRUD), no permite que podamos hacer resaltar los aspectos más importantes de nuestras aplicaciones. Ahora vamos a ver unos tips para darle un poco de cariño al aspecto visual de los admins.

Para este ejemplo, vamos a crear una aplicación de prueba que se encarga de monitorear el estado de las aplicaciones móviles en algún AppStore.

## Primeros Pasos

En Potassium al instalar ActiveAdmin ya se incluye por defecto `active_skin` (también está en la mayoría de proyectos existentes), si no, hay que agregarlo al Gemfile:

```ruby
gem "active_skin"
```

Una vez instalada la gema, al cargar el administrador se va a ver así:

![Interfaz inicial](/images/customizing-active-admin/default-ui.png)
