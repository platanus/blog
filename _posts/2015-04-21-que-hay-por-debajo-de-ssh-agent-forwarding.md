---
title: ¿Qué hay por debajo de SSH Agent Forwarding?
author: arturopuente
layout: post
tags:
    - ssh
    - ssh-agent
---

Siempre me había hecho esa pregunta, pero empecemos por definir cómo funciona el proceso a grandes rasgos: el agent forwarding nos permite conectarnos a otros servidores autenticándonos mediante credenciales que tenemos localmente en nuestra computadora, de forma que el servidor intermedio sólo hace de puente entre ambos.

Parece bastante mágico, pero es un proceso bastante simple y quien realiza la mayor parte del trabajo es el agente SSH. Al iniciar una comunicación simple con un servidor, hacemos algo como esto:

`ssh usuario@servidor.platan.us`

Lo que pasa por debajo es que el proceso de SSH le envía al servidor nuestro usuario, el daemon de SSH en servidor nos pregunta por nuestro password, que si coincide, nos dará acceso a una sesión.

Esto tiene problemas de seguridad y conveniencia evidentes. Por un lado, estamos obligados a ingresar el password cada vez que queramos acceder a una sesión o recurso, es tedioso e inseguro. Además, alguien podría ingresar a nuestra sesión por fuerza bruta o simple suerte.

Para resolver estos problemas utilizamos la autenticación mediante llaves. Para esto, debemos generar un par de llaves pública/privada, y guardar el contenido de llave pública en el archivo `authorized_keys` del servidor. Este archivo se encuentra en la carpeta `$HOME/.ssh`, cada usuario tiene uno, donde se guardan todas las llaves públicas del usuario.

Cuando ejecutemos `ssh usuario@servidor.platan.us` el servidor ya no nos va a pedir un password. El flujo es el siguiente:

- El servidor genera un número aleatorio y, utilizando la llave pública que le hemos otorgado, nos lo devuelve cifrado (esto también se conoce como key challenge).
- Nuestro cliente SSH recibe este número cifrado, e intenta descifrarlo mediante el uso de nuestra llave privada (de tener configurado un passphrase para desbloquear la llave privada, en este momento nos lo pedirá).
- Una vez obtenido el número original, le añadirá el ID único de la sesión actual para generar un hash MD5 y enviarlo de vuelta al servidor.
- El servidor genera a su vez un hash MD5 del número que nos envió junto al ID de la sesión y lo compara con el hash que recibe. Si coinciden, nos provee acceso.

Ahora bien, esto significa que cada comunicación ya no requiere de un password de usuario, sin embargo, sí nos pedirá el passphrase con el que hemos cifrado nuestra llave privada en cada comunicación. El rol del agente es actuar como intermediario entre la comunicación del cliente local de SSH y el del servidor, de forma que es el agente el que se encarga de descifrar por primera vez la llave privada y almacenar este resultado para usos posteriores permitiéndonos ingresar nuestro passphrase sólo una vez.

Al ingresar a un tercer servidor mediante SSH, el primer servidor al que nos conectamos sólo reenvía los key challenges y respuestas de nuestro cliente, al hacer un deploy con [Negroku](https://github.com/platanus/negroku), realmente somos nosotros los que nos autenticamos con GitHub para traer los últimos cambios, el servidor actúa como intermedio.

Esto también nos sirve para autenticarnos en servidores compartidos (donde poner nuestra llave privada puede traer problemas!), por ejemplo, si ejecutamos `ssh -A usuario@servidor.platan.us` le indicamos a SSH que use nuestro agente para autenticarnos en las demás conexiones.

Si desde nuestra sesión en `servidor.platan.us` tratamos de clonar un repositorio de GitHub mediante SSH, esa conexión se hará directamente con nuestro agente local, mientras el servidor al que nos conectamos originalmente actúa como intermedio.

```bash
# Primero intentamos conectarnos a GitHub para ver que todo está
# configurado correctamente, nos devuelve una confimación similar a:
# Hi username! You've successfully authenticated
usuario@computadora $ ssh -T git@github.com

# Nos conectamos a nuestro servidor con el flag -A para indicarle que
# queremos usar Agent Forwarding
usuario@computadora $ ssh -A usuario@servidor.platan.us

# Para comprobar que efectivamente esto está funcionando, en nuestro servidor
# podemos ejecutar el siguiente comando
usuario@servidor.platan.us $ echo "$SSH_AUTH_SOCK"
/tmp/ssh-QzMkdu4328/agent.4328
# Esta es la ubicación del socket con el que se está realizando el forward

# Al clonar un repo, el cliente SSH del servidor de Platanus usa
# nuestro agente local para autenticarse con GitHub
usuario@servidor.platan.us $ git clone git@github.com:usuario/proyecto.git
```

Esto es muy útil para hacer deploys, porque no tenemos que utilizar deploy keys, ni subir nuestras llaves públicas a un servidor, basta con que tengamos nuestras credenciales de GitHub locales.

Si queremos que esto sea el comportamiento por defecto al conectarnos al servidor, podemos dejarlo especificado en el archivo `$HOME/.ssh/config` de la siguiente manera:

```
 Host servidor.platan.us
   ForwardAgent yes
```

Esto le indica a SSH que cada conexión a `servidor.platan.us` debe ser hecha mediante forwarding.
