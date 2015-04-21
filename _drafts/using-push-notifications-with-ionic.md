---
title: "Usando push notifications con Ionic"
layout: post
authors:
    - emilioeduardob
    - renemoraales
categories:
    - angularjs
    - ionic
    - push
---

Utilizando [ngCordova][ngcordova] junto con el plugin [$cordovaPush][cordova-push] tenemos mucho trabajo hecho para utilizar notificaciones Push de Google y Apple. Pero igual hay cierto trabajo que queda hacerlo en nuestras apps.

En este blog post, propongo un pequeño servicio para hacer la vida un poquito más facil. El servicio maneja la parte del registro y persistencia del token de Push en LocalStorage.

## Requerimientos

Aparte de tener instalado ngCordova, tendremos que usar el fork `platanus/PushNotifications`

```
ionic plugin add https://github.com/platanus/PushNotification.git
```


## PushNotifications Service

Este servicio encapsula el trabajo de `$cordovaPush` y provee un par de funciones

## APIs públicas

- PushNotifications.ensureRegistration: Registra la applicación con Google GCM o Apple APN si es necesario y guarda los tokens(Registration ID o Device ID). Este metodo debe llamarse siempre que se quieren recibir notificaciones Push, no solo para registrar la primera vez. El plugin `PushNotification` (nuestro fork), ya mantiene un control de estado de registro. En GCM se registrará únicamente la primera vez y cuando se actualice la versión de la App.

- PushNotifications.getToken: Devuelve el device Token o GCM ID

- PushNotifications.onMessage: Funcion que es llamada en cada mensaje push recibida

## Ejemplo implementado en `app.js`

{% gist emilioeduardob/01e4a8fa9088dfd7e4ba app.js %}

> `ensureRegistration` puede recibir dos callbacks de success y error

```js
PushNotifications.setGcmSenderId('XXX');
PushNotifications.ensureRegistration(function(regInfo) {
  console.log("Registrado!", regInfo.source, regInfo.token);
}, function() {
  console.log("Error al registrar");
});
```

## Mensajes en Android

`PushPlugin` generará notificaciones si el payload del mensaje recibido contiene ciertos atributos:
- `message` es usado para establecer el texto de la notificación.
- `sound` el nombre del archivo a reproducir(sin extension en Android.). El sonido debe ser guardado en platforms/android/res/raw/cool_sound.wav
- `smallIcon` el nombre del icono para la notificación (sin extension en Android.). Si smallIcon no existe, el plugin busca un icono llamado `ic_stat_notify` y si no existe utiliza el icono de la app
- `title` establece el titulo (Generalmente el nombre de la App)
- `msgcnt` (opcional) agrega un numero al costado inferior derecho de la notificación.

El plugin tambien agrega otro atributo al mensaje. `coldstart`, que ayuda a determinar si al tocar la notificación, la app se inicio o ya estaba abierta. Este atributo se agrega al mensaje recibido en el callback de `onMessage`

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

Los datos enviados en iOS no vienen dentro de un payload

{% gist emilioeduardob/01e4a8fa9088dfd7e4ba PushNotifications.js %}

[ngcordova]: http://ngcordova.com/
[cordova-push]: http://ngcordova.com/docs/plugins/pushNotifications/
