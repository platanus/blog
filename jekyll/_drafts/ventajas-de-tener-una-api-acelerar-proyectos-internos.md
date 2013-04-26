---
title: Ventajas de tener una Web API - Acelerar proyectos internos
author: Agustin Feuerhake
layout: post
categories:
    - api
    - humanos
---
###Cómo un API puede servir para **acelerar al departamento TI** de una empresa.

Antes de leer esto, te recomiendo haber leido [¿Qué es una Web Api?][1]

<img src="/images/monkey-running.jpg" style="float:left;width:300px;margin:20px;" alt="Fotografía gentileza de www.flickr.com/photos/larrysarallo/"/>

Todos sabemos lo odioso que se torna el departamento de TI en una empresa. Y es que todos en la empresa los estamos llamando, alegando y apurando. Pero es que son tan lentos! Claro, pero es que todo lo tienen que hacer ellos! Pooobres TI. Cómo que pobres! si no hacen nada!

Entre los buenos ingenieros de software es bien sabido que agregar más programadores a un mismo proyecto lo único que logra es hacer que todo vaya aún más lento! 

Contraintuitivo ¿verdad?

Pero es verdad. Cuando muchas personas tienen acceso a modificar un código de muchas líneas, se hace casi imposible avanzar con velocidad. El conocimiento está demasiado repartido y todos dependen de todos.

Lo ideal es subdividir al equipo de TI en equipos muy chicos, cercano a 3 personas, y definir la interacción entre los códigos de estos equipos solamente mediante APIs. Muchas veces lo que hacen las empresas es tener equipos pequeños dedicados a construir mientras otros se dedican a probar lo que se hace y otros a mantener lo que hay, pero en general eso logra que los ingenieros dedicados a construir no tomen verdadera responsabilidad de lo que hacen. Lo mejor es que quien construye, prueba y responde ante lo que hizo. Para poder dividir los equipos, lo mejor es dividir el proyecto también. Las Web APIs son una manera muy eficiente de separar las partes de un proyecto. Se trata de la evolución de lo que en los años 90 se conocía como SOA (Service Oriented Architecture).

Para la mayoría de las empresas, dividir sus sistemas a través de APIs puede ser la solución a su lentitud informática.

Poor ejemplo! **Evernote**, una conocida suite de aplicaciones diseñada para crear documentos y archivar información: Tienen aplicaciones para Microsoft Windows, OS X, Android, iOS (iPhone, iPad, iPod Touch), Windows Mobile, Windows Phone, WebOS, Maemo, BlackBerry (incluyendo BlackBerry Playbook), incluso tienen un beta para Symbian S60,  blah, blah, blah... SILENCIO! ¿Cómo logran mantener taantas versiones, todas funcionando igual de bien y más encima permiten que un usuario se cambie de plataforma y mantenga todos sus documentos?

Así es. Tienen un API donde los "usuarios" son los programadores de la misma empresa. De hecho, el 99% de los usuarios de la API de Evernote son internos de la compañía. Así pueden tener muchos equipos pequeños, cada equipo se preocupa de la construcción de la aplicación en una plataforma, pero todos usan la misma API.

En Platanus nos dedicamos a apoyar a las empresas que quieren transformar sus sistemas y adoptar una arquitectura orientada a servicios, donde el equipo de TI ya no pierde tiempo en coordinación, y donde se hace evidente que contratando más gente se puede avanzar de manera veloz. 

[1]: #
