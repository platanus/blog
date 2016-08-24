---
layout: post
title: Services, Commands y otros poderosos patrones en Rails
author: felbalart
tags:
  - rails
  - patterns
  - services
---
Muchas veces a la hora de desarrollar tenemos claridad sobre el código que tenemos que escribir, pero no sobre dónde ponerlo.  En Platanus, al desarrollar en Rails, hemos ido decantando estrategias de diseño, y nos servimos de opciones más allá de models y controllers para organizar nuestro código.  Las poderosas herramientas que proponemos en este post son Services, Commands, Utils y Values.  Algunas cosecha platanesca, otras ya bien difundidas en la comunidad Rails.  No hay porque ajustarse a las 6 carpetas que crea Rails por defecto, podemos crear otras para estructurar nuestros proyectos.

## ¿Para qué me sirve todo esto?
Estos innovadores tipos tienen varias razones de ser, pero la motivación fundamental radica en el principio de mantener tanto los models como controllers *skinny*.  Con esto logramos mantener las responsabilidades lo más acotadas posible por cada elemento de nuestro código.  Nos basamos en el principio de *Single responsibility principle* (SRP) para tener una app lo más modular posible.  ¿Qué ganamos?  Código legible, donde es fácil ubicar donde esta cada pieza y que hace cada clase.  Código mantenible, donde los cambios se hacen sobre un archivo específico breve, y no tenemos que entrar a entender y hacerle riesgosas modificaciones a clases con miles de líneas de código.  Logramos *DRYness*, en caso que cierta pieza se requiera usar en distintas partes de la aplicación.  También permite el unit testing. En fin, ventajas múltiples.

## La gema Power-Types

Si bien es posible trabajar con estos tipos creándolos como POROs (simples clases Ruby), en Platanus no lo hacemos así.  Usamos la gema [Power Types](https://github.com/platanus/power-types), que brinda una estructura y sintaxis especial para cada tipo.  Cada Service o Command que creemos hereda de una clase base,  que le otorga esta manera amistosa para crearse, inicializarse y ejecutarse.
También provee generadores, que además de crear el archivo para la clase del nuevo Servicio, nos genera su respectivo archivo de tests rspec.  Por último, al instalar esta gema en un proyecto, se crean en el root las respectivas carpetas para cada tipo.

## Services

El concepto de Services en Rails goza de cierta difusión en la comunidad, apareciendo junto con Rails 4.  Como lo define [Dave Copeland en su artículo dedicado](http://multithreaded.stitchfix.com/blog/2015/06/02/anatomy-of-service-objects-in-rails/), el rol de un service es **tener el código de un porción especifica de la lógica de negocio**.  El service es una clase que expone uno o varios métodos públicos para llevar a cabo tareas puntuales. Si son más de uno, se enmarcan dentro de un contexto común que describe el nombre del servicio.  Este nombre debe ser un sustantivo, seguido de “_service”.  


Imaginemos una aplicación para escuchar música via streaming, y que recomienda al usuario canciones y artistas según las canciones que ha escuchado.  En este contexto, creamos un servicio para obtener las canciones o artistas relacionados, en base a una canción dada.
Usando PowerTypes podemos crearlo usando el generador

    $ rails generate service RelatedMediaService source

Este generador crea la clase en base a una plantilla, además de los archivos rspec.  Sobre esta base escribimos la lógica del servicio:

```ruby
class RelatedMediaService < PowerTypes::Service.new(:source)

def get_songs
 related_songs  = []
 related_songs << Song.where(genre: @source.genre)
 related_songs << Song.where(year: @source.year, country: @source.country)
 #some other song relating bussiness logic
 related_songs
end

def get_artists
 related_artist = []
 related_artist << Artist.where(genre: @source.genre)
 #some other artist relating bussiness logic

end  
```

La sintaxis de Power Types para instanciar y llamar a los métodos del servicio es muy sencilla

```ruby
media_service = RelatedMediaService.new(source: my_source)
related_songs = media_service.get_songs
related_artists = media_service.get_artists
```

Con respecto al output de un Servicio, en general hay 2 posiblidades.  Lo común es qus sea a través de valores de retorno de sus métodos, pero también es válido que modifique directamente los objectos sobre los que actúa.


## Commands
Los commands también están a nuestra disposición.  Corresponden a una versión más funcional de services.  Se usan para operaciones acotadas e independientes.  Un command solo expone un método perform, que ejecuta la acción que describe el nombre del command.  Este nombre, a diferencia de los services, debe ser un verbo. Y también se diferencia ya que no debe guardar estado si no que ejecutarse de una vez a partir de los argumentos que recibe al inicializarse.

Los services y commands atacan objetivos similares, tal vez todavía son difusas para ti las diferencias.  Nos podemos hacer las siguientes preguntas para identificar cuando corresponde usar un service en vez de un command:

* ¿La clase que vamos a crear debe ofrece más de una función, y por lo tanto debe exponer 2 o más métodos públicos?

* ¿Necesitamos una clase que guarde su estado, y se hacen varias llamadas en distintos momentos a una misma instancia de ella?

Si la respuesta fue afirmativa para alguna, corresponde un service.  De lo contrario, crea un command.

Consideremos como ejemplo un command que recibe una canción y nos retorna su idioma, si es que es capaz de deducirlo.
Usando Power-Types podemos crearlo usando el generador

    $ rails generate command GuessSongLanguage song

Esto crea una clase con el método perform en blanco, que es el que debemos implementar obligatoriamente

```ruby
class GuessSongLanguage < PowerTypes::Command.new(:song)
 ENG_WORDS = ["of", "and", "the", "that"]
 ESP_WORDS = ["que", "de", "y", "para"]

 def perform(song)
  unless song.artist.county.nil?
   song.artist.county.language
  elsif !((ENG_WORDS & song.title.split).empty?)
   "english"
  elsif !((_WORDS & song.title.split).empty?)
   "español"
  end
 end
end
```

Y para ejecutar un comando creado con Power Types (no hay que instanciar, solo se ejecuta)

    $ language = GuessSongLanguage.for(song: let_it_be)



Bajo estos conceptos de Services y Commands, dentro de nuestro equipo surgió la duda:
**¿Puede un servicio que ofrece múltiples funciones, usar diferentes commands para realizar cada una de estas funciones?**
 Esto es una decisión de diseño, donde depende el caso.  Pero en general, tomamos en cuenta dos cosas para **mantener todo en un servicio**:

  * Hay mucha lógica común entre las funciones provistas.

  * Son funciones simples. Si alguna de las funciones tomara mucha complejidad nos inclinamos a poner la lógica en un command, y dejar la función en el servicio como wrapper del command.

Al desarrollar nos topamos con múltiples decisiones de este tipo.  Por lo general en Platanus tratamos de ser prácticos y velar por las formas más simples y legibles, aquellas que permiten que el código lo pueda entender facilmente cualquier miembro del equipo que entre al proyecto.

## Utils
Como una alternativa adicional surge los Utils para cuando necesitamos varias funciones relacionadas muy acotadas e independientes de contexto.  El mejor ejemplo es el módulo Math de Ruby, que ofrece los métodos cos(x), sin(x), log(x), sqrt(x) etc.  La forma de implementar un Util es usando los modules de Ruby. Le ponemos un nombre que agrupe a las funciones y en el las cremos directamente.  Por ejemplo, en el contexto de nuestra app musical, imaginemos que puede aplicar efectos de sonido sobre las canciones, estos podrían estar encapsulados en un Util:

```ruby
module SongEffects  
  extend self

  def amplify(song, factor)
    song.samples.map {|sample| sample * factor}
  end

  def invert(song)
    song.samples.reverse
  end

  def pitch_up(song)
    song.samples.reject {|s| song.samples.index(s).even?}
  end

#any other song effect
```

## Values

El tipo Value cumple un objetivo bastante distinto a los de los patrones que ya hemos visto. Nos sirve para definir un modelo fuera del schema de la aplicación, que por ende no llega a persistirse en la base de datos.  Nos permite definir un tipo de objeto con sus atributos y crear instancias, que son usadas por servicios de la aplicación, pero siempre almacenadas solo en memoria.  Son útiles a la hora de pasar un conjunto de datos entre clases, donde a veces conviene encapsular estos datos en un objeto, más que usar un hash o arreglo.  Hacerlo así nos permite tener claridad de como será el valor de retorno.  Además es posible definir métodos para un Value si queremos agregarle alguna lógica sencilla.

Por ejemplo, consideremos el servicio del comienzo del post RelatedMediaService, que actualmente entrega un arreglo de artistas o canciones relacionadas a modo de recomendación para que el usuario escuche.  Supongamos que queremos recibir eso, pero además saber a partir de que canción que escuché viene la recomendación, y un puntaje de 1 a 5 que indique la calidad de la sugerencia.  Una opción es que el servicio retorne un arreglo de hashs del tipo:
```
{recommendation: #<Artist: name: "The Doors">, source: #<Song: artist: "Led Zeppelin", title: "Stairway to Heaven">, score: 3}
```
Sin embargo, aporta más claridad que nos retorne un arreglo de objetos de tipo Recommendation, que es un Value compuesto así:

```ruby
class Recommendation
  attr_accessor :suggestion, :source, :score

  def initialize(suggestion, source, score)
   @suggestion = suggestion
   @source = source
   @score = score
  end

  def to_s
  	"#{suggestion} because you listened #{source} (#{score} points)"
  end
end
```

## Manos a la obra

Bueno, ya conoces estos patrones, y la gema Power Types.  ¡Ahora a usarlos!  Es importante que se difundan las convenciones que son un aporte como propuesta de diseño de un proyecto Rails.  El que todo nuestro equipo comparta estos patrones facilita la comprensión de código creado por los distintos miembros.  Al ver uno de estos tipos de clase ya se tiene una idea que función cumple, y también podemos saber dentro de que parte del proyecto encontrar cierta lógica que estamos buscando.

