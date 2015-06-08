---
title: Push con Rails y Ionic, de la A a la Z
author: renemoraales
layout: post
tags:
  - ionic
  - rails
  - push
  - cordova

---

Las notificaciones push son una parte fundamental de las aplicaciones móviles modernas y aunque en el último tiempo han surgido muchas herramientas para alivianar la carga (incluyendo nuestra librería para Ionic), el proceso completo aún puede resultar un poco engorroso. 

En este post, queremos explicar en su totalidad los pasos a seguir para lograr notificaciones en una aplicación Rails/Ionic, tanto en Android como en iOS, utilizando nuestras herramientas favoritas e incluso algunas desarrolladas aquí mismo en Platanus.

## 1. Preparándolo todo

### 1.1. Certificados y perfiles en iOS

El proceso de certificados requerido por Apple es probablemente la parte más complicada de configurar las notificaciones push en nuestra aplicación. Hay dos partes en términos de "permisos":

- El **servidor**, que requiere un certificado de APNs y la llave privada utilizada para generarlo,
- y el **cliente**, que requiere un perfil de provisionamiento para compilar la aplicación de modo que reciba correctamente las notificaciones.

Las instrucciones a continuación debemos ejecutarlas en el [Developer Center de Apple](https://developer.apple.com/account/overview.action). Necesitaremos una cuenta individual suscrita al programa de desarrolladores, o ser administradores en un equipo.

Primero, si no lo hemos hecho con anterioridad, crearemos un Identifier para nuestra aplicación, que sera específico a ésta y deberá coincidir con el que indicamos en el `config.xml` (por ejemplo, us.platan.madbill). 

Luego, crearemos un archivo CSR (certificate request) desde nuestra máquina, que usaremos para generar el certificado APNs para emitir notificaciones push a nuestra app. Para esto, abriremos la app **Keychain Access** en OS X, y en el menú, elegiremos la opción `Keychain Access > Certificate Assistant > Request a Certificate From A Certificate Authority`. Ingresaremos nuestro correo electrónico y nombre, y elegimos la opción **Save to disk** para guardar el `.certSigningRequest` resultante.

Volveremos a los Identifiers, donde seleccionaremos la opción Editar en el Identifier que creamos anteriormente, y en la sección Push Notifications, nos aseguraremos de marcar la casilla **Enabled** y pulsaremos el botón para crear el certificado que corresponde, ya sea **Development** o **Production**. Se nos pedirá entonces el archivo `.certSigningRequest` que generamos anteriormente, lo elegimos y pulsamos **Generate**. Finalmente, hacemos click en el botón **Download** para descargar el certificado recién generado, y lo abrimos con Keychain Access para guardarlo en nuestro llavero.

En iOS, las notificaciones push sólo funcionan en dispositivos reales. Por esto, necesitaremos obtener el UUID del iPhone, iPod o iPad que usaremos para probar nuestra aplicación y agregarlo en la sección **Devices** de la página de desarrolladores. 

Como última medida, asegurarse que quien sea que compilará la app tenga un certificado de desarrollo iOS en su llavero. Para generarlo, desde la máquina donde se usará, se debe generar un `.certSigningRequest` como está detallado más arriba, y luego, en la sección **Certificates** de la página de desarrolladores, crear el certificado de iOS Development usando el archivo recién generado. Este certificado deberá ser aprobado por un administrador antes de poder ser descargado y utilizado. Una vez completado ese proceso, guardar e instalar el certificado.

Finalmente, si no lo hemos hecho anteriormente, debemos generar un **Provisioning Profile** para nuestra aplicación, que XCode utilizará para saber cómo firmar las builds de nuestra app. En la sección **Provisioning Profiles**, crearemos uno nuevo y nos aseguraremos de tres cosas: especificar el **Identifier** del perfil para que coincida con el de nuestra app, incluir el certificado del desarrollador que compilará la aplicación, e incluir el dispositivo donde se correrá la app. Una vez generado, descargamos e instalamos el perfil en la máquina donde haremos nuestras builds.

### 1.2. Google Cloud Messaging

Configurar GCM (Google Cloud Messaging) para enviar y recibir notificaciones push es mucho más simple que en iOS, ya que utilizaremos una API Key típica para enviar y un identificador numérico para suscribirnos desde el cliente.

En la [Consola de Desarrolladores de Google](https://console.developers.google.com), crearemos un nuevo proyecto con el título que queramos. Se nos va a redirigir a un dashboard para este proyecto, donde tomaremos nota del **Project Number** que aparece arriba en gris. Este es nuestro Sender ID y lo utilizaremos en la app.

Luego, en la barra lateral, vamos a `APIs & auth > APIs`, y entramos a **Cloud Messaging for Android**. En esa pantalla, clickeamos **Enable API**. Una vez habilitada la API, nuevamente en la barra lateral, accedemos a `APIs & auth > Credentials` y bajo **Public API access**, pulsamos el botón **Create new Key** y elegimos la opción **Server key**. En el cuadro de texto que se presenta, debemos anotar las IPs desde las cuales queremos permitir el envío de peticiones, pero para efectos de desarrollo, podemos simplemente dejar el campo vacío. Finalmente, le damos a **Create**. Tomamos nota del API key que aparecerá, el cual usaremos en el servidor.

## 2. Registrando dispositivos y recibiendo notificaciones

En nuestras aplicaciones **Ionic**, utilizamos **PushPlugin** y **ngCordova** para facilitar nuestra vida respecto al manejo de notificaciones push. Sin embargo, quisimos ir un paso más allá y creamos **la librería [angular-push](https://github.com/platanus/angular-push)**, que facilita lo más posible el registro de dispositivos y manejo de notificaciones entrantes a través de Angular.

Primero, nos aseguramos de tener el [PushPlugin](https://github.com/phonegap-build/PushPlugin) y [ngCordova](http://ngcordova.com/) en nuestra app. Instalamos con `bower install platanus-angular-push` y añadimos la dependencia `PlPush` a nuestra app:

```javascript
angular.module('yourapp', ['PlPush']);
```

Si queremos notificaciones de Android, corremos el siguiente código dentro de nuestro `app.config` de Angular, especificando el GCM Sender ID (o Project Number) que recuperamos anteriormente:

```javascript
app.config(function(PushConfigProvider){
  PushConfigProvider.setGcmSenderId('Tu Sender ID');
});
```

Finalmente, ya puedes manejar las notificaciones utilizando `onMessage`, y recuperar el token de tu dispositivo con `ensureRegistration`, el cual deberás enviar al servidor para poder especificar a qué terminal quieres enviar las notificaciones. También podrás recuperar el token de push con `getToken`. Estos métodos heredan del servicio `PushSrv` que debes inyectar, por ejemplo, en tu `app.run` de Angular:

```javascript
app.run(function(PushSrv){
  PushSrv.onMessage(function(notification){
    // Manipula la notificación como sea necesario.
  });
  
  PushSrv.ensureRegistration(function(){
    console.info('Registered! Push Token is ' + PushSrv.getToken());
  }, function(){
    console.error('Error when registering device.');
  });
});
```

En iOS recibirás un Device Token y en Android, un Registration ID, pero su uso es prácticamente el mismo.

No está demás repetir que para que iOS entregue el token correcto, debes compilar la app con el Provisioning Profile correspondiente y correrla en un dispositivo, ya que el iOS Simulator no tiene soporte para APNS.

## 3. Enviando notificaciones

Hay múltiples opciones para enviar notificaciones, como Amazon SNS, Mixpanel u otros tantos servicios. Queda a discreción de cada uno determinar cuál es la mejor opción, pero para no salirnos del entorno Rails, utilizaremos la gema [rpush](https://github.com/rpush/rpush).

### 3.1. Instalando Rpush

Agregamos `rpush` a nuestro `Gemfile`, hacemos un `bundle install` y corremos `bundle exec rpush init` en el directorio de nuestra app Rails para instalar la gema.

### 3.2. Exportando los certificados iOS

Necesitamos exportar el Certificado Push de Apple para que nuestro servidor pueda leerlo y conectarse con el servidor APNS.

Para esto, abriremos nuevamente el **Keychain Access**, escogiendo Certificates en la barra lateral, y buscaremos el que lleva por nombre **Apple Development IOS Push Services** acompañado por el identificador de nuestra aplicación. Lo expandimos clickeando la flecha al lado izquierdo, seleccionaremos tanto el certificado como la clave privada, y haciendo click derecho, pulsamos **Exportar 2 ítems**. Guardamos el archivo como un `.p12`. Opcionalmente, podemos ingresar una contraseña para proteger el certificado, pero puedes dejarlo en blanco.

Ahora, debemos convertir este certificado a un archivo `.pem`, que es el formato que lee Rpush. Correremos el siguiente comando:

**Si guardaste tu certificado con contraseña, corre:**

`openssl pkcs12 -clcerts -in <ARCHIVO_EXPORTADO>.p12 -out <ARCHIVO_A_CREAR>.pem`

**Si guardaste sin contraseña:**

`openssl pkcs12 -nodes -clcerts -in <ARCHIVO_EXPORTADO>.p12 -out <ARCHIVO_A_CREAR>.pem`

Finalmente, toma nota de la ruta de este archivo `.pem` recién creado, pues la utilizaremos a continuación.

### 3.3. Creando las apps en Rpush

Rpush nos pide crear algunos registros ("apps") en nuestra base de datos, los cuales apuntarán a un Certificado APNS o ID de GCM en particular, y que utilizaremos para enviar nuestras notificaciones. Por ejemplo, podemos tener dos apps para cada plataforma, una de desarrollo y una de producción, y utilizar uno de los dos según corresponda.

**En iOS:**

```ruby
app = Rpush::Apns::App.new
app.name = "ios_app"
app.certificate = File.read("...") # la ruta del .pem que generamos antes
app.environment = "sandbox" # sandbox o production, según corresponda
app.password = "certificate password" # si creamos nuestro certificado con contraseña, ingresarla aquí
app.connections = 1
app.save!
```

**En Android:**

```ruby
app = Rpush::Gcm::App.new
app.name = "android_app"
app.auth_key = "..." # la API Key de GCM que generamos anteriormente
app.connections = 1
app.save!
```

### 3.4. Enviando las notificaciones

Echamos a andar el servidor de **Rpush** corriendo el comando `bundle exec rpush start`. Con este proceso funcionando, sólo tenemos que crear registros en el recurso de Notificación de Rpush, apuntando a la app que creamos en el paso anterior. Estos quedarán encolados y el servidor se encargará de despacharlos:

**En iOS:**

```ruby
n = Rpush::Apns::Notification.new
n.app = Rpush::Apns::App.find_by_name("ios_app") # La app que creamos antes
n.device_token = "..." # El token entregado por la app Ionic
n.alert = "Has recibido un nuevo mensaje!" # El texto de tu notificación
n.data = { foo: :bar } # Payload de tu notificación
n.save!
```

**En Android:**

```ruby
n = Rpush::Gcm::Notification.new
n.app = Rpush::Gcm::App.find_by_name("android_app") # La app que creamos antes
n.registration_ids = ["..."] # El token entregado por la app Ionic, puede ser un array para enviar a múltiples dispositivos
n.data = { title: "Nombre de tu App", message: "Has recibido un nuevo mensaje!" }
n.save!
```

En Android, `data` debe contener `title` y `message` para que el sistema operativo muestre automáticamente las notificaciones. Si falta uno de estos campos, la aplicación seguirá recibiendo los mensajes, pero no llegarán como las alertas normales.

En el caso de iOS, `alert` contiene el mensaje de la notificación que se muestra al usuario, mientras que `data` es un payload que podrás leer cuando manejes la llegada de la notificación en tu app Ionic.

## 4. Cerrando

Configurar las notificaciones push puede resultar un proceso complicado y un tanto agotador, pero esperamos que esta guía aclare los principales puntos de dificultad que representa tener que habilitar esta funcionalidad en nuestra aplicación. A medida que vayamos tomando nuevas decisiones en nuestro flujo de trabajo o encontremos la manera de facilitar aún más el proceso, iremos actualizando esta guía.
