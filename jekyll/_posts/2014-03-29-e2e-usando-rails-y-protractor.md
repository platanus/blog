---
title: E2E Testing usando Rails + Protractor
author: Leandro Segovia
layout: post/leandro-segovia
categories:
    - rails
    - angularjs
    - protractor
    - testing
    - e2e
---

Buen día!, les cuento un cuento... Un día, tuve que participar en el desarrollo de una aplicación que utiliza **Rails + AngularJs**. El desarrollo avanzó y todos éramos felices. Hasta que un día, la aplicación empezó a fallar. Comenzó a notarse verdaderamente la necesidad de realizar tests de integración. Comencé la búsqueda de herramientas para realizar este tipo de pruebas en aplicaciones que utilizan **Angular** y rápidamente me encontré con **Protractor**. Estaba feliz! Protractor parecía encarnar todo lo que necesitaba para llevar adelante mi labor. Sin embargo, había un pequeño/gran detalle que esta herramienta no resolvía: **la integración con mi backend**. Por esto, decidí hacer este post con el objeto de mostrarles como llevar adelante **End to End tests** con Protractor y una posible solución al problema planteado.

Estos temas trataré:

1. Conceptos básicos
2. Pasos para la instalación
3. Configuración
4. Puesta en marcha
5. Intregación con Rails
6. Referencias

## Conceptos básicos

* **[Protractor][1]**: es un end to end framework construído sobre **Selenium WebDriverJS**
* **[Selenium WebDriverJS][2]**: es un servidor escrito en **Java** que acepta comandos y los envía a un navegador. Esto se implementa a través de un controlador del navegador específico para cada navegador que envía los comandos y trae los resultados de regreso.

## Pasos para la instalación

* Obviamente, tener la aplicación **Rails** up and running.
* Instalar **Protractor** (se debe tener instalado **npm**)

```bash
npm install -g protractor #instala jasmine, webdriver-manager, etc.
```

* Instalar WebDriverJS para utilizar con un navegador específico.

```bash
webdriver-manager update
```

## Configuración

* Decidir la ubicación de mis specs. Por ej, podría ser dentro del directorio: **/app/test/e2e/specs**
* Crear un archivo **protractor.conf.js** dentro de: **/app/test/**. En este archivo se puede configurar una gran cantidad de cosas, yo pondré uno de ejemplo con lo básico para funcionar:

```js
exports.config = {
	// Donde corre Selenium
	seleniumAddress: 'http://localhost:4444/wd/hub',

	// Donde corre mi app
	baseUrl: 'http://localhost:3001',

	// Este es importante porque le dice a Protractor donde
	// tengo la directiva ng-app. Por defecto es en body...
	rootElement: 'html',

	// En este array indico donde están mis specs. Se pueden usar
	// expresiones regulares y se ejecutaran en el orden en que se
	// ingresaron en el array.
	specs: ['./e2e/specs/*.spec.js'],

	// En este atributo params se puede dejar disponible valores
	// que podré acceder dentro de mis pruebas. Esto es algo de lo
	// que me pretendo deshacer integrando mis test con Rails.
	params: {
		storeUser: {
			username: 'user',
			password: '123456'
		}
	},

	// Protractor permite trabajar con Mocha o Jasmine y permite configurar ambos.
	jasmineNodeOpts: {
		showColors: true
	}
};
```
* Supongamos que queremos probar que funcione correctamente un formulario que tiene:

1. **Email** que debe ser válido.
2. **teléfono** que debe ser válido.

Entonces, creamos la prueba dentro del directorio **/app/test/e2e/spec**. Por ej: podríamos crear el archivo: **form.spec.js** con el siguiente contenido:

```js
describe('Form', function() {
	beforeEach(function () {
		header = element(by.className('header'));
		errorMsg = element(by.css('span[ng-if="error"]'));
	});

	it("shows form", function() {
		browser.get('/form');
	});

	it("shows invalid format error with invalid phone", function() {
		var phoneInput = element(by.model('data.phone'));

		phoneInput.clear();
		phoneInput.sendKeys('teléfono iválido');
		header.click();
		expect(errorMsg.isPresent()).toBe(true);
	});

	it("shows invalid format error with invalid email", function() {
		var storeEmailInput = element(by.model('data.email'));

		storeEmailInput.clear();
		storeEmailInput.sendKeys('email inválido');
		header.click();
		expect(errorMsg.isPresent()).toBe(true);
	});
});
```

En el ejemplo podemos ver como **Protractor** nos facilita métodos para interactuar con el browser. Como por ej:

```js
browser.get('some url') //que nos facilita acceder a una página determinada.
```
También podemos ver:

```js
by.model('some angulars model') //que nos permite referenciar un elemento HTML a través del ng-model que tiene asociado.
```

Como estas, hay muchas otras funciones que **Protractor** nos provee y estas, se pueden encontrar [aquí][3].


##Puesta en marcha

* Levantar el webserver

```bash
rails s -p 3001 #http://localhost:3001
```

* Levantar Selenium

```bash
webdriver-manager start #http://localhost:4444
```

* Correr las pruebas

```bash
protractor test/protractor.conf.js #el path del archivo de configuración de Protractor
```

Haciendo esto deberíamos ver en el terminal como corren nuestras pruebas...

##Intregación con Rails

Hasta aquí todo perfecto, tenemos nuestros specs corriendo y todo marcha bien, pero nuestras pruebas están corriendo sobre una base de datos de desarrollo!!! Probar si un email o teléfono es válido es algo que uno puede hacer sin generar información basura en la db. Pero que pasa si yo quiero probar que mi formulario efectivamente guarde los datos y que pasa si además, quiero ver si lo que acabo de ingresar se muestra correctamente en una lista? de aquí es que nace la necesidad de integrar mis pruebas a un entorno/backend preparado para el testing.
Para solucionar esto de manera simple, se puede generar una rake task que haga lo siguiente:

1. borrar la db de test (para asegurarnos de trabajar en un entorno limpio)
2. crear la db de test
3. matar cualquier proceso que corra en el puerto 3001 (donde correrá el webserver)
4. matar cualquier proceso que corra en el puerto 4444 (donde corre Selenium)
5. levantar web server
6. levantar selenium
7. cargar la data de test en la db
8. correr tests
9. matar Selenium y webserver

La rake task podría ser algo así:

```ruby
namespace :app do
  namespace :ptor do
    desc 'Runs protractor tests'
    task :run, [:show_output, :webserver_port] => :environment do |t, args|
      require 'tasks/protractor.rb'
      output = args[:show_output] =~ (/(true|t|yes|y|1)$/i) ? true : false
      port = args[:webserver_port].to_i
      port = [*3000..3050].include?(port) ? port : 3001
      App::Protractor.run_specs output, port
    end
  end
end

module App
  module Protractor
    def self.run_specs _show_ouput = false, _webserver_port = 3001
      require 'net/http'
      #me aseguro de que todo lo que cree se guarde en la base de datos de test
      ActiveRecord::Base.establish_connection('test')
      @show_ouput = _show_ouput
      @webserver_port = _webserver_port

      begin
        prepare_test_db
        load_test_data
        run_webserver
        run_selenium
        run_tests
        kill_webserver
        kill_selenium

      rescue Exception => e
        kill_webserver
        kill_selenium
        show_error(e)
      end
    end

    private

      def self.show_error exc
        puts exc.message
        puts exc.backtrace.join("\n")
      end

      def self.msg _message
        puts _message
      end

      def self.run_cmd _cmd
        cmd = _cmd
        cmd = "#{_cmd} > /dev/null 2>&1" unless @show_ouput
        system(cmd)
      end

      def self.run_webserver
        msg "Starting webserver..."
        kill_webserver
        thread = Thread.new { run_cmd("bundle exec rails s -p #{@webserver_port} -e test") }
        wait_for_webserver
        thread
      end

      def self.run_selenium
        msg "Starting Selenium..."
        kill_selenium
        thread = Thread.new { run_cmd("webdriver-manager start") }
        wait_for_selenium
        thread
      end

      def self.prepare_test_db
        msg "Preparing test database..."
        run_cmd("bundle exec rake db:reset RAILS_ENV=test")
        run_cmd("bundle exec rake db:setup RAILS_ENV=test")
      end

      def self.load_test_data
        msg "Loading test data..."
        #Aquí se debería cargar lo necesario para correr los specs.
        #Por ej se podría crear un usuario para que no falle el proceso de login.
        #Esto es una implementación básica por lo que podría hacerse algo mucho más
        #inteligente que permita asociar un spec con un archivo que cargue los
        #datos para trabajar.
        @user = User.create(user: 'someuser', passwd: '123456'))
      end

      def self.run_tests
        #aquí sobreescribo los parámetros configurados en protractor.conf.js
        #y los reemplazo por los que acabo de crear en el método load_test_data
        params = [
          "--baseUrl http://localhost:#{@webserver_port}",
          "--params.storeUser.username='#{@user.user}'",
          "--params.storeUser.password=#{@user.passwd}"]
        system("protractor ../web/test/protractor.conf.js #{params.join(" ")}")
      end

      def self.wait_for_webserver
        wait_for_server "http://localhost:#{@webserver_port}/index"
      end

      def self.wait_for_selenium
        wait_for_server "http://localhost:4444/wd/hub/static/resource/hub.html"
      end

      def self.wait_for_server _url
        sleep 1 until server_ready? _url
      end

      def self.kill_webserver
        kill_server @webserver_port
      end

      def self.kill_selenium
        kill_server 4444
      end

      def self.kill_server _port
        #kills whatever is running on given port
        run_cmd("kill -9 $(lsof -i :#{_port} -t)")
      end

      #utilizo este metodo para preguntar si mi app y Selenium estan
      #levantados antes de comenzar a correr los test.
      def self.server_ready? _url
        begin
          url = URI.parse(_url)
          req = Net::HTTP.new(url.host, url.port)
          res = req.request_head(url.path)
          !res.code.blank?
        rescue
          false
        end
      end
  end
end
```

Luego para correr la tarea puedo hacer:

```bash
rake app:ptor:run #Por defecto no muestra ouput y el webserver corre en el 3001
```

Para correr mostrando el ouput de webserver, selenium, migraciones, etc.

```bash
rake app:ptor:run[true] # Se puede pasar true, t, yes, y 1
```

Para cambiar el puerto del webserver agrego un segundo parámetro. Por defecto corre en el 3001

```bash
rake app:ptor:run[true,3006]
```

##Referencias

* [Protractor en Github][4]
* [Documentación Protractor][5]
* [egghead: Introducción Protractor][6]
* [Julie Ralph: E2E Angular testing con Protractor][7]
* [Jim Lavin: Introducción E2E testing con Protractor][8]
* [Un muy buen post que nos explica cuando usar protractor][9]

[1]: https://github.com/angular/protractor
[2]: http://docs.seleniumhq.org/projects/webdriver/
[3]: https://github.com/angular/protractor/blob/master/docs/api.md
[4]: https://github.com/angular/protractor
[5]: https://github.com/angular/protractor/blob/master/docs/api.md
[6]: https://egghead.io/lessons/angularjs-getting-started-with-protractor
[7]: https://www.youtube.com/watch?v=aQipuiTcn3U
[8]: https://www.youtube.com/watch?v=idb6hOxlyb8
[9]: http://www.yearofmoo.com/2013/09/advanced-testing-and-debugging-in-angularjs.html#presentation-slides-plus-video