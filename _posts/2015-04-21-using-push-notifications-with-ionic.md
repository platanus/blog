---
title: "Usando push notifications con Ionic"
layout: post
authors:
    - emilioeduardob
    - renemoraales
tags:
    - angular
    - ionic
    - notifications
    - cordova
redirect_from: angularjs/ionic/push/2015/04/21/using-push-notifications-with-ionic.html
---

Utilizando [ngCordova][ngcordova] junto con el plugin [$cordovaPush][cordova-push] tenemos mucho trabajo hecho para utilizar notificaciones Push de Google y Apple. Pero igual hay cierto trabajo que queda hacerlo en nuestras apps.

En este blog post, introducimos `angular-push`, una librería de JavaScript que nos ayuda a manejar el registro y persistencia de los tokens de Push en nuestra aplicación Ionic.

## Requerimientos

Debemos instalar en nuestra aplicación la librería `angular-push` y nuestro fork del plugin de notificaciones de Cordova, `platanus/PushNotifications`.

```
bower install platanus-angular-push --save
ionic plugin add https://github.com/platanus/PushNotification.git
```

Recuerda agregar `ngCordova` y `angular-push` a tu archivo HTML y en las dependencias de tu aplicación:

```
angular.module('yourapp', ['PlPush']);
```

## Cómo usar PushSrv

Esta librería incluye el servicio `PushSrv`, que usarás para reigstrar dispositivos y manejar las notificaciones entrantes. El caso de uso más común, para ambos Android e iOS, sería:

{% gist ReneMoraales/42b5537bcff7bbea4180 app.js %}

### Registrando servicios

**PushSrv.ensureRegistration(success, error)**

Este método registrará la aplicación en el dispositivo, sólo si es necesario. Opcionalmente acepta dos callbacks, uno en caso de éxito y otro en caso de error. El servicio maneja ls diferencias del proceso entre Android y iOS. Si resulta en éxito, el dispositivo está listo para recibir notificaciones.

### Recuperando el token de push

**PushSrv.getToken()**

Esta función devuelve el token generado durante el proceso de registro. Lo necesitarás para enviar notificaciones al dispositivo desde un servidor, por lo que deberás persistirlo en una base de datos, por ejemplo. En iOS, este token corresponde al APNS Device Token, mientras que en Android, es el GCM Registration ID. Además, el token quedará guardado en LocalStorage para uso futuro.

### Manejando notificaciones entrantes

**PushSrv.onMessage(callback)**

Este metodo recibe un callback, que se ejecuta al momento de recibir una notificación push y al que se le pasa como argumento el objeto que contiene los datos del Mensajes.

## Notas sobre Android

En Android, necesitarás definir tu Sender ID de Google Cloud Messaging para registrar dispositivos. Así como se muestra en el ejemplo de más arriba, puedes usar el PushConfigProvider para setear el Sender ID.

Además, `PushPlugin` sólo generará una alerta de notificación si el payload del mensaje recibido contiene ciertos atributos:
- `message`, usado para establecer el texto de la notificación.
- `title`, que establece el título (generalmente el nombre de la App)

Además puedes incluir estos:
- `sound`, el nombre del archivo a reproducir (sin extensión). El sonido debe ser guardado en `platforms/android/res/raw/`.
- `smallIcon`, el nombre del icono para la notificación (sin extensión). Si smallIcon no existe, el plugin busca un icono llamado `ic_stat_notify` y si no existe utiliza el icono de la app.
- `msgcnt` (opcional) agrega un numero al costado inferior derecho de la notificación.

El plugin tambien agrega otro atributo al mensaje. `coldstart`, que ayuda a determinar si la app se inició al tocar la notificación o ya estaba abierta. Este atributo se agrega al objeto recibido en el callback de `onMessage`.

```json
{
  "coldstart":"true",
  "foreground":"0",
  "payload": {
    "message":"Mi mensaje genial",
    "msgcnt":"3",
    "title": "App Title or Whatever",
    "sound": "cool_sound",
    "smallIcon": "my_custom_icon"
  }
}
```

## Mensajes en iOS

En iOS las notificaciones las crea el propio sistema. El mensaje que se recibe es diferente al de Android, puesto que los atributos enviados no vienen dentro de un objeto payload:

```json
{"sound":"default","alert":"Mi mensaje genial","hello":"world","foreground":"0"}
```

[ngcordova]: http://ngcordova.com/
[cordova-push]: http://ngcordova.com/docs/plugins/pushNotifications/
