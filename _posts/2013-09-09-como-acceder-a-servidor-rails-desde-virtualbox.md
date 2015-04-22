---
title: Cómo acceder a un servidor rails local desde virtualbox
author: agustinf
layout: post
tags:
    - rails
    - front-end
redirect_from: rails/frontend/2013/09/09/como-acceder-a-servidor-rails-desde-virtualbox.html
---

Explorer es tal vez la peor pesadilla de cualquier desarrollador front-end. Hace un tiempo en platan.us nos cambiamos todos a Mac y tengo la sensación de que gracias a esto la productividad ha subido notablemente. No se si es solo una sensación, pero al menos la sensación me gusta!

Si tienes un Mac y necesitas probar tu aplicación web desde Explorer, una alternativa es instalar VirtualBox en tu Mac e instalar alguna versión de Windows con Microsoft Explorer en la máquina virtual. Después vas a tener que acceder a tu página, a la que acostumbras entrar poniendo `localhost:3000`, pero no puedes entrar así, porque estás en otra máquina:

Para poder pedirle una página a tu servidor rails corriendo en tu Mac (probablemente Webrick o Thin) entra a la configuración de las redes de VirtualBox haciendo click en el par de monitores que aparece en la esquina inferior derecha. Donde aparecen los adaptadores de red, elige NAT. Después te vas a explorer y pones `http://10.0.0.2:3000` Ojo con el "http://", Explorer me hizo perder 20 minutos a mi por no ponerle el protocolo a la dirección.

Suerte!
