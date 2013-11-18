---
title: Lectura y escritura rápida mediante Redis – parte 1
author: Felipe
layout: post/felipe-campos
categories:
    - database
    - noSQL
    - cache
---

Al día de hoy, el sistema de almacenamiento en cache de preferencia es Redis. Poco a poco ha desplazando a su viejo contendor Memcached, y hace algunos años, se viene posicionando como el principal actor en el acceso y almacenamiento rápido de datos en múltiples sistemas. Twitter, Yahoo, Instagram, Flickr y GitHub son unos de los tantos que han confiado en esta potente base de datos. Pero ¿Por qué todo el mundo ama tanto a Redis? Sigue leyendo y encontraras la respuesta.

### ¿Que es Redis? ###

Redis es una base de datos NoSQL en memoria, de tipo key-value. Soporta estructuras de varios tipos: cadenas, hashes, listas, conjuntos o conjuntos ordenados (mostraré esto en detalle mas adelante). A diferencia de otros sistemas como Memchached, persiste los datos en disco (aun que esta característica es opcional). Al tener la capacidad de almacenar datos, no puede catalogarse como un sistema de almacenamiento en cache, pero en realidad, hasta el momento, no he visto ni un solo caso en donde se utilice Redis como un sistema principal de almacenamiento.

Su principal característica es el alto rendimiento, por lo mismo, generalmente se utiliza bajo entornos donde el transito de datos sea considerable y la rapidez sea un factor determinante.

Aun que todos concuerdan que Redis es una base de datos muy veloz, y que consume muy pocos recursos (utiliza  7.5 mb. De disco Aproximadamente en ejecución), sus propios creadores llaman a tener mucho cuidado al momento de hacer comparativas. Hay que saber distinguir bajo que entornos Redis se comporta de manea realmente eficiente.

Es muy difícil demostrar la velocidad real de la base de datos, pero aun así, se pueden encontrar multitud de artículos que tratan el tema. Particularmente me perecieron dos muy interesantes: **[El primero](http://redis.io/topics/benchmarks)** viene del sitio oficial de Redis, e intenta responder que tan rápido realmente es Redis. **[El segundo](http://ruturaj.net/redis-memcached-tokyo-tyrant-and-mysql-comparision/)**, entrega valiosa información comparativa (mediante varios benchmarks), mostrando bajo distintas circunstancias a Redis vs sistemas como Memcache, bases de datos integradas y bases de datos relacionales tradicionales.

### Primeros pasos ###

Antes de comenzar, lógicamente debemos instalar Redis.

Si tienes Mac y brew, corre el siguente comando:

```bash
brew install redis
```

Si tienes Ubuntu:

```bash
sudo apt-get install redis-server
```

Si no quieres utilizar un package manager, puedes descargar el ultimo tar.gz estable desde **[este link](http://redis.io/topics/quickstart)**, en donde también encontraras las instrucciones para realizar la instalación.

Para comenzar a trabajar, es necesario levantar al menos un servidor Redis.

Si instalaste Redis mediante brew, corre el siguente comando:

```bash
brew services start redis
```

Si tienes Ubuntu:

```bash
cd utils
sudo ./install_server.sh

```

Una manera alternativa es la siguente (valido para cualquier tipo de instalación):

```bash
# Dependiendo de la forma como realizaste la instalación el path donde se ubica el archivo redis.conf puede variar
redis-server /redis/redis.conf
```

Ahora ya estamos listos para probar que el servidor Redis esta funcionando correctamente. Para ingresar al command-line interface (CLI) del servidor, en una nueva pestaña de tu terminal ejecuta el siguente comando:

```bash
redis-cli
```

Si ves la palabra redis seguida por una ip (por defecto localhost) y un puerto(por defecto 6379), entonces la instalación y puesta en marcha ha sido todo un éxito.

### El archivo redis.conf ###

Siempre que levantamos un servidor Redis, debemos hacer referencia al archivo Redis.conf (ya sea indicando explícitamente el path, o ejecutando alguno de los scripts que nos proveen nuestro queridos gestores de packetes). Tal como se mostro anteriormente la ubicación de este varia dependiendo de la forma en que realizaste la instalación. Si por ejemplo, instalaste mediante brew, debería estar en: /usr/local/etc/redis.conf.

Sin utilizar mucha imaginación, podemos deducir que este archivo es el responsable de configurar Redis. Gracias a el, definimos cosas tan básicas como el puerto en donde correrá el servidor, hasta cosas tan complejas como la forma correcta de ejecución dependiendo de la arquitectura sobre la cual esta funcionando la base de datos.

Algunos ejemplos de opciones de configuración son:

```bash
# para correr Redis como un demonio (por defecto no)
daemonize

# para escoger el puerto del servidor (por defecto 6379)
port

# para cerrar la conexión cuando un cliente esta desconectado por N segundos (por defecto 0)
timeout

# para indicar cada cuanto tiempo se persistirán los datos
# si ha ocurrido 1 o mas transacciones en 60 segundos, almacena los datos
save 900 1
# si han ocurrido 10 o mas transacciones en 300 segundos, almacena los datos
save 300 10
# si han ocurrido 10.000 o mas transacciones en 60 segundos, almacena los datos
save 60 10000
```


Y con esto damos por concluida la primera parte. En la próxima entrada mostrarte los distintos tipos de key/value que soporta Redis para accessar y almacenar datos, interactuaremos con el CLI y revisaremos las distintas estrategias para correr multiples bases de datos (para distintas aplicaciones y entornos).