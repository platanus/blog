---
title: Initial setup con Ionic Framework, Gulp y Protractor!
author: Emilio y Leandro
layout: post
categories:
    - Ionic
    - Gulp
    - Protractor
---

El objetivo de este post es mostrar brevemente como se puede crear una aplicación móvil usando [Ionic framework](http://ionicframework.com/), [gulp](http://gulpjs.com/) como build system y [Protractor](http://angular.github.io/protractor) como ent-to-end test framework.

## Dependencias necesarias

Instala [Android Stand-alone SDK](https://developer.android.com/sdk/installing/index.html)
Agrega las `platform-tools` y `tools` del sdk a tu path:

```bash
$ export PATH=${PATH}:/path-to-your-sdk/platform-tools:/path-to-your-sdk/tools
```

Agrega la variable de entrono `ANDROID_HOME` de esta manera

```bash
$ export ANDROID_HOME=/path-to-your-sdk/tools
```

Por último:

```bash
$ npm install -g ionic cordova gulp
```

Una vez que tengas todo instalado pasamos a la configuración de tu aplicación...

## Configuración

Deberás clonarte la applicación [template](https://github.com/platanus/starting-ionic-template). Una vez que hayas hecho esto, ejecutarás en el root de la app:

```bash
$ npm install -d #para instalar dentro de /node_component todas las dependencias del archivo .package.json
$ bower install #para instalar Ionic dentro de /src/bower_components
```

Luego, agregarás un archivo de ambiente. Esto puedes hacerlo copiando */enviroments/development.json.example*. Por ej: */enviroments/development.json*. Dentro de este archivo debes agregar todas las variables que deseas estén disponibles en tu aplicación. Recuerda que puedes tener tantos archivos como ambientes tengas.
Después deberás crear el archivo *.nodenv-vars*. del mismo modo que hiciste con el enviroment, copiando de *.nodenv-vars.example*.

Eso es todo! ahora sólo resta correr la aplicación en tu browser o en un Android.

## Correr la aplicación

### En el browser

Para dejar corriendo, usando */src* como fuente, la app en [http://localhost:9000](http://localhost:9000) hacemos:

```bash
$ gulp
```

### En Android

Para procesar y copiar los archivos de */src* y colocarlos dentro de */www* utilizando las variables del ambiente elegido ejecutamos:

```bash
$ gulp build --env my_enviroment_name
```

Luego conecto el móvil utilizando USB y ejecuto lo siguiente para compilar y abrir la aplicación en el teléfono:

```bash
$ cordova run android
```

Listo! con esto ya tienes la aplicación template lista para hacer deploy! Claro, sólo resta que modifiques los archivos necesarios para convertir esta triste aplicación en un grandioso proyecto.
Algunos de los que puedes/debes modificar son:

* Todo dentro de */src*. Aquí puedes agregar controllers, services, templates, models, y todo lo que necesites (No olvides incluir los nuevos archivos en index.html)
* En */scss/ionic.app.scss* puedes agregar tus propios estilos o modificar los que Ionic trae por defecto.
* En *.bower.json* puedes agregar todas las librerías que necesites.

Antes de irnos, dejamos una brevísima guía de instalación para realizar end-to-end test usando Protractor:

## Testing con Protractor

Dentro del directorio */test/specs* puedo poner todos mis specs nombrandolos de la siguiente forma: **xxx_spec.js** donde xxx es claramente el nombre de mi spec (mirar */test/specs/app_spec.js* para tener un ejemplo)
Luego de tener mis specs, ejecuto:

```bash
$ npm install webdriver-manager #La primera vez
$ webdriver-manager update --standalone #La primera vez
$ webdriver-manager start
$ gulp server
$ protractor protractor.conf.js #para correr los test
```

*protractor.conf.js* contiene (obviamente) configuración relacionada con protractor, vale la pena darle un vistazo...
