---
layout: post
title: Manejando upload de archivos con Pallet & Friends
author: ldlsegovia
tags:
  - rails
  - angular
---

En este post, voy a hablarles sobre una gema para Rails y un conjuto de librerías Angular que tienen como objetivo menejar fácilmente el upload de archivos a una API. Esto va desde la selección del archivo por parte del usuario hasta su persistencia en la base de datos.

Para explicar cada una de estas herramientas, voy a basarme en un supuesto feature:

*Como un **usuario del sistema**, debo poder:*

- *Ingresar a mi perfil.*
- *Ingresar mi nombre .*
- *Seleccionar una foto de perfil.*
- *Seleccionar un archivo de tipo .pdf*
- *Enviar los datos al servidor a través de una API.*

Este feature, comprende las siguientes tareas:

### Tareas indispensables

- Crear la vista de perfil de usuario.
- Agregar text inputs para ingresar el nombre de usuario.
- Agregar control (file input) para seleccionar la foto de perfil y el archivo.
- Enviar toda la información a la API (nombre, foto y archivo).
- Asociar la información con una instancia del modelo `User`.

### Mejoras

- Mostrar un preview de los archivos seleccionados.
- Mostrar una barra de progreso.

Para situarlos en contexto, imaginen que tenemos una aplicación cliente (básicamente el formulario en el perfil de usuario) que utiliza Angular y una API construída en Rails. Dicho lo anterior, plantearé una solución a las tareas enumeradas.

#### Tareas: "Crear la vista de perfil de usuario" y "Agregar text inputs para ingresar el nombre de usuario"

Bueno, sobre las primeras dos tareas no hay nada que decir. Creo que todos los que llegaron a leer hasta aquí, saben como agregar un formulario con un input de texto.

#### Tarea: Seleccionar una foto de perfil y el archivo.

Para realizar esta tarea, usaremos la librería [Angular Pallet](https://github.com/platanus/angular-pallet/tree/v2.0.0) en el cliente y [Rails Pallet](https://github.com/platanus/rails_pallet/tree/v2.0.1) del lado del servidor.

Vamos a implementar el ejemplo para ver como funciona todo más detalladamente.

**Del lado del servidor...**

[Rails Pallet](https://github.com/platanus/rails_pallet/tree/v2.0.1) es un [Rails engine](http://guides.rubyonrails.org/engines.html) que permite a través de un endpoint, recibir archivos, almacenarlos y devolver al cliente identificadores unívocos de esos archivos. ¿Por qué usar identificadores? de esta manera y sobre todo en el caso de tener que enviar varios archivos, podremos hacer upload de cada uno de ellos de manera asincrona, obteniendo feedback en cada request.

Para usar la gema, simplemente debemos instalarla. El hacer esto dejará disponible, en nuestra aplicación Rails, el endpoint: `POST http://my-rails-app/uploads`. Este endpoint es al que apuntaremos en la directiva, para subir los archivos.

**Del lado del cliente...**

[Angular Pallet](https://github.com/platanus/angular-pallet/tree/v2.0.0) es una librería Angular, que implementa una directiva construída sobre [ng-file-upload](https://github.com/danialfarid/ng-file-upload), que nos permite seleccionar archivos y enviarlos al servidor a través de un endpoint configurado en la propia directiva. El objetivo no es reemplazar a ng-file-upload sino valernos de su potencial mientras implementamos lo necesario para "conversar" con [Rails Pallet](https://github.com/platanus/rails_pallet/tree/v2.0.1) de manera simple y transparente.

Luego de instalar la librería, debemos incluir, en nuestro formulario, la directiva de esta manera:

```html
<form>
  <input name="user[name]" placeholder="Ingrese su nombre...">
  <pallet-file-selector
    upload-url="http://my-rails-app/uploads"
    button-label="Seleccione Foto..."
    ng-model="user.photoIdentifier">
  </pallet-file-selector>
  <pallet-file-selector
    upload-url="http://my-rails-app/uploads"
    button-label="Seleccione Archivo..."
    ng-model="user.fileIdentifier">
  </pallet-file-selector>
</form>
```

Eso es todo!

**Funcionamiento**

El hacer click en el botón "Seleccione Foto...", realizará un `POST` a `http://my-rails-app/uploads` con el archivo seleccionado. En el back-end, la gema persistirá, en una tabla `uploads`, la foto y devolverá un identificador relacionado a la instancia de la clase `Pallet::Upload` que se acaba de crear. La respuesta de la API contendrá este identificador que será almacenado en la variable `user.photoIdentifier` definida en algún lado del controllador Angular que maneja el formulario. Los mismos pasos se repetiran si se hace click en "Seleccione Archivo...".

Si se han seguido correctamente los pasos, se obtendrá el siguiente resultado:

![angular-pallet-example](/images/pallet/angular-pallet.gif)

#### Tareas: "Enviar toda la información al API (nombre, foto y archivo)" y "Asociar la información con una instancia del modelo `User`"

Una vez que se han seleccionado los archivos, se enviará toda la data al servidor. Para lograr esto, debemos:

**Del lado del servidor...**

- Crear el modelo `User` de la siguiente manera:

```ruby
class User < ActiveRecord::Base
  has_attached_upload :photo, upload: { use_prefix: true }
  has_attached_upload :file, upload: { use_prefix: true }
end
```

El método `has_attached_upload` le indica al modelo `User` que los atributos, `photo` y `upload`, trabajan con la gema `Pallet`.

- Crear el controlador `UsersController`:

```ruby
class UsersController < ApplicationController
  def update
    @user.update_attributes(permitted_params)
    redirect_to @user
  end

  def permitted_params
    params.require(:user).permit(
      :photo_upload_identifier, :file_upload_identifier, :name)
  end
end
```

> Obviamente, se debe crear la ruta para actualizar los datos del usuario (`PUT /users/:id`)

**Del lado del cliente...**

Simplemente vamos a agregar unos inputs al formulario y a apuntarlo a la ruta de update de usuario.

```html
<form method="put" action="/users/22">
  <input name="user[name]" placeholder="Ingrese su nombre...">
  <pallet-file-selector
    upload-url="http://my-rails-app/uploads"
    button-label="Seleccione Foto..."
    ng-model="user.photoIdentifier">
  </pallet-file-selector>
  <pallet-file-selector
    upload-url="http://my-rails-app/uploads"
    button-label="Seleccione Archivo..."
    ng-model="user.fileIdentifier">
  </pallet-file-selector>
  <input type="hidden" ng-value="user.photoIdentifier" name="user[photo_upload_identifier]" />
  <input type="hidden" ng-value="user.fileIdentifier" name="user[file_upload_identifier]" />
  <input type="submit" value="Send" />
</form>
```

Eso es todo!

**Funcionamiento**

Luego de seleccionar los archivos, el hacer click en el botón submit del formulario, enviará a `PUT /users/22` los datos de la siguiente manera:

```ruby
{
  "user"=>{
    "name"=>"leandro",
    "photo_upload_identifier"=>"jhWMLgG1hu",
    "file_upload_identifier"=>"XwA5Xo5aFe"
  }
}
```

Cuando la data llegue al controllador, la gema buscará en la tabla `uploads` aquellos archivos que se correspondan con los identificadores recibidos (`photo_upload_identifier` y `file_upload_identifier`) y copiará los mismos, en los atributos correspondientes (`photo` y `file`) del usuario que se está actualizando. Luego, borrará de la tabla `uploads` las entradas utilizadas.

Hasta aquí, hemos cubierto las "Tareas indispensables" para satisfacer la necesidad planteada. En adelante, plantearé algunas mejoras en relación a la experiencia de usuario.

#### Mejora: Mostrar un preview de los archivos seleccionados.

Para llevar a cabo esto, podemos utilizar la librería: [Angular Doc Preview](https://github.com/platanus/angular-doc-preview/tree/v1.1.0). Esta, brinda al usuario a través de una directiva, la previsualización de cualquier tipo de archivo proporcionando simplemente la url del mismo.

Como se puede ver en el código debajo, la directiva `pallet-file-selector` nos permite ejecutar un callback en el momento en que se completa un upload. Del primer parámetro de la función, se puede acceder a la información sobre el archivo que se acaba de cargar. Entre la información obtenida, viene la url del documento que necesitaremos en el `doc-preview`.

En la vista...

```html
<form method="put" action="/users/22">
  <input name="user[name]" placeholder="Ingrese su nombre...">
  <pallet-file-selector
    success-callback="onPhotoUploadSuccess(uploadData)"
    upload-url="http://my-rails-app/uploads"
    button-label="Seleccione Foto..."
    ng-model="user.photoIdentifier">
  </pallet-file-selector>
  <doc-preview
    render-image-as="thumb"
    document-name="photoData.file_name"
    document-url="photoData.download_url">
  </doc-preview>
  <pallet-file-selector
    upload-url="http://my-rails-app/uploads"
    button-label="Seleccione Archivo..."
    ng-model="user.fileIdentifier">
  </pallet-file-selector>
  <doc-preview
    success-callback="onFileUploadSuccess(uploadData)"
    document-name="fileData.file_name"
    document-url="fileData.download_url">
  </doc-preview>
  <input type="hidden" ng-value="user.photoIdentifier" name="user[photo_upload_identifier]" />
  <input type="hidden" ng-value="user.fileIdentifier" name="user[file_upload_identifier]" />
  <input type="submit" value="Send" />
</form>
```

En el controller Angular...

```javascript
$scope.onPhotoUploadSuccess = function(_uploadData) {
  $scope.photoData = _uploadData;
}

$scope.onFileUploadSuccess = function(_uploadData) {
  $scope.fileData = _uploadData;
}
```

![angular-doc-preview-example](/images/pallet/angular-doc-preview.gif)

#### Mejoras: "Mostrar una barra de progreso" y "Manejar errores"

Para agregar esta funcionalidad, podemos utilizar la librería [Angular Progress](https://github.com/platanus/angular-progress/tree/v1.1.0). Esta inlcluye una simple directiva para mostrar el progreso de una acción. En este caso, el upload de archivos. Para hacer funcionar esta directiva, necesitamos proporcionarle dos valores: `loaded` y `total`. Afortunadamente, `pallet-file-selector` nos permite ejecutar un callback que viene con información de progreso de la carga de un archivo. Así quedaría nuestro ejemplo con esta nueva incorporación:

En la vista...

```html
<form method="put" action="/users/22">
  <input name="user[name]" placeholder="Ingrese su nombre...">
  <pallet-file-selector
    success-callback="onPhotoUploadSuccess(uploadData)"
    progress-callback="onPhotoProgress(event)"
    upload-url="http://my-rails-app/uploads"
    button-label="Seleccione Foto..."
    ng-model="user.photoIdentifier">
  </pallet-file-selector>
  <progress progress-data="photoProgress"></progress>
  <doc-preview
    render-image-as="thumb"
    document-name="photoData.file_name"
    document-url="photoData.download_url">
  </doc-preview>
  <pallet-file-selector
    upload-url="http://my-rails-app/uploads"
    button-label="Seleccione Archivo..."
    ng-model="user.fileIdentifier">
  </pallet-file-selector>
  <progress type="bar" progress-data="fileProgress"></progress>
  <doc-preview
    success-callback="onFileUploadSuccess(uploadData)"
    progress-callback="onFileProgress(event)"
    document-name="fileData.file_name"
    document-url="fileData.download_url">
  </doc-preview>
  <input type="hidden" ng-value="user.photoIdentifier" name="user[photo_upload_identifier]" />
  <input type="hidden" ng-value="user.fileIdentifier" name="user[file_upload_identifier]" />
  <input type="submit" value="Send" />
</form>
```

En el controller Angular...

```javascript
$scope.onPhotoProgress = function(_event) {
  $scope.photoProgress = _event;
}

$scope.onFileProgress = function(_event) {
  $scope.fileProgress = _event;
}
```

![angular-progress-example](/images/pallet/angular-progress.gif)

Espero a esta altura podamos decir que:

1. La necesidad ha sido cubierta.
2. Se ha mejorando significativamente la experiencia de usuario.
3. Las herramientas presentadas han facilitado la resolución del problema planteado.

Me animaría a pensar que están de acuerdo conmigo en las dos primeras pero no tanto en la tercera, debido un poco al manejo de callbacks que hay que hacer para "ensamblar" las directivas. Con esto en mente, se creó una nueva librería que viene a resolver este caso típico de manera más transparente. La librería en cuestión es un bundle de las 3 anteriores y se llama: [Angular Pallet Bundle](https://github.com/platanus/angular-pallet-bundle/tree/v2.0.0)

Así quedaría la implementación de nuestro ejemplo con esta nueva librería:

```html
<form method="put" action="/users/22">
  <input name="user[name]" placeholder="Ingrese su nombre...">
  <pallet-upload-handler
    render-image-as="thumb"
    no-document-text="No hay foto..."
    upload-url="uploads"
    ng-model="user.photoIdentifier">
  </pallet-upload-handler>
  <pallet-upload-handler
    no-document-text="No hay archivo..."
    upload-url="uploads"
    progress-type="bar"
    ng-model="user.fileIdentifier">
  </pallet-upload-handler>
  <input type="hidden" ng-value="user.photoIdentifier" name="user[photo_upload_identifier]" />
  <input type="hidden" ng-value="user.fileIdentifier" name="user[file_upload_identifier]" />
  <input type="submit" value="Send" />
</form>
```

![angular-pallet-bundle-example](/images/pallet/angular-pallet-bundle.gif)

Bueno, esto ha sido todo pero, antes de irme, voy a listar un par de cosas útiles que se pueden hacer con estas librerías, que no incluí en los ejemplos para no complejizar el post innecesariamente.

- General
  - Todas las directivas vienen con una hoja de estilo propuesto. Puedes usarla, o crear las propias.
- [Rails Pallet](https://github.com/platanus/rails_pallet/tree/v2.0.1)
  - Si deseas modificar el controller de `/uploads` o montar la funcionalidad en una ruta distinta, puedes usar este [generador](https://github.com/platanus/rails_pallet/tree/v2.0.1#creating-your-own-uploadscontroller).
- [Angular Pallet](https://github.com/platanus/angular-pallet/tree/v2.0.0)
  - Permite setear la opción `multiple` en `true` y con esto seleccionar varios archivos a la vez. En este caso, el `ng-model` contendrá un array con identificadores.
  - Permite suscribirse a varios callbacks (`error-callback`, `remove-callback`), no sólo a progress y success.
  - Esta librería tiene su análoga para [cordova](https://cordova.apache.org/) y su nombre es: [Cordova Pallet](https://github.com/platanus/cordova-pallet)
- [Angular Doc Preview](https://github.com/platanus/angular-doc-preview/tree/v1.1.0)
  - Permite pasar a la directiva la opción `document-extension`. Es útil en los casos donde el tipo de archivo no se puede inferir por la url del mismo.
  - Por defecto, las imágenes se mostrarán como un thumbnail y los documentos como un link con un icono. Si se desea, se puede mostrar imágenes como links seteando la opción `render-image-as` en `link`.
- [Angular Progress](https://github.com/platanus/angular-progress/tree/v1.1.0)
  - Dentro de la `progress-data`, se puede pasar el key `error: true`. De esta manera, se puede avisar a la directiva que añada la clase `error` al wrapper de la misma.
