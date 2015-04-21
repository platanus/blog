---
title: Pequeña guía sobre escribir historias
author: juliogarciag
layout: post
tags:
    - programming
    - patterns
    - comments
    - style
---


A riesgo de sonar redundante o extremista, tengo que defender el argumento de que programar es una actividad mucho más expresiva que técnica. Nosotros no sólo somos humanos tratando de explicarle a la máquina qué es lo que queremos y cómo queremos que haga las cosas, sino que tratamos de expresar qué es lo que necesitamos de tal forma que podemos poner en orden las ideas en nuestra mente a la vez que almacenamos ese conocimiento en un programa.

Es imperativo, entonces, pensar en qué es lo que hace que un programa sea fácil de leer y entender para el futuro. Uno de esos aspectos importantes es la habilidad para nombrar partes de un programa de tal forma que expresen lo que realmente hacen. Pero, además, es importante saber cómo articular el programa para que exprese el algoritmo detrás de él de forma que los humanos podamos seguir su desarrollo.

A la hora de programar creamos redes de comunicación, partes que se comunican, que envían datos y reciben datos, que operan sobre los datos y que hacen algo. Todos los componentes son como una historia que comienza con datos y termina haciendo algo o retornando más datos. En ese sentido, programar es como escribir pequeños relatos que conforman un relato mayor, pequeñas historias que se van incrementando conforme pasa el tiempo y que suelen iniciarse de los modos más inesperados.

# Un programa

Este programa va a crear una lista de música usando las 10 canciones más populares del primer artista que encuentre en una búsqueda a la api de Spotify. Debería funcionar algo así.

```bash
$ ruby create_playlist_of_artist.rb "Led Zeppelin"
```

# Una implementación veloz

Supongamos que mi almuerzo estará listo en muy poco tiempo y que quiero mi programa ya porque quiero almorzar escuchando un mix entre las 10 más populares canciones de Led Zeppelin, Pink Floyd, Oasis, Nirvana y como 10 bandas más. Entonces, luego de un buen rato, programando con el único objetivo de terminar y sin la menor gana de refactorizar nada, terminamos con algo así:

```ruby
require 'spotify_client'

COUNTRY_CODE = ENV['SPOTIFY_COUNTRY_CODE']
USER_ID = ENV['SPOTIFY_USER_ID']

spotify = Spotify::Client.new({
  access_token: ENV['SPOTIFY_ACCESS_TOKEN'],
  raise_errors: true
})

artist_name = ARGV.first

if artist_name && artist_name != ''
  # Search for artists
  search_results = spotify.search(:artist, artist_name)
  artists = search_results['artists']
  if artists
    items = artists['items']
    if items && items.size > 0
      artist_id = items.first['id']

      # Search for top tracks
      top_tracks_results = spotify.artist_top_tracks(artist_id, COUNTRY_CODE)

      if top_tracks_results && top_tracks_results['tracks']
        top_tracks = top_tracks_results['tracks']

        # Create a playlist
        playlist_name = "Top Ten : #{artist_name}"

        created_playlist = spotify.create_user_playlist(USER_ID, playlist_name)
        if created_playlist
          playlist_id = created_playlist['id']

          # Inserting the tracks in the playlist
          track_uris = top_tracks.map { |track| track['uri'] }

          spotify.add_user_tracks_to_playlist(USER_ID, playlist_id, track_uris)
        end
      end
    end
  end
end
```

Hay varios problemas en este código, comenzando desde el hecho que es el equivalente a un único método que hace todo el trabajo y de que no es una clase sino el contexto global el que funciona. Dejando de lado esos problemas, ¿es ésta una historia bien contada?

En una vista rápida no queda claro qué es lo que está haciendo (ustedes lo saben porque se los conté antes). Deberíamos leer cada línea cuidadosamente para enterarnos de lo que ha pasado. Cuando leemos una historia que debe ser leída cuidadosamente, es obvio que nos provocará más cansancio mental que si no. Hay casos en los que simplemente no seguiremos leyendo, y nosotros no queremos que nuestro yo del futuro se canse de leer y odie a nuestro yo de este momento.

## ¿Qué convierte a una mala historia es una mala historia?

Partamos desde la estructura de una historia. Una historia fácil de leer es aquella que puede seguirse secuencialmente. Si una historia comienza contando algo y luego se mete en un detalle aburrido para luego continuar con lo que ocurre, el lector se chocara con una pared mental que no va a ser muy fácil de entender. Una historia simple es una historia secuencial y una historia compleja es una historia que puede tener varios finales.

Si bien es cierto que no podemos evitar interactuar distinto para varios casos, es importante que, por lo menos, en lo que leemos, el *happy path* sea fácilmente visible. El *happy path* debería resaltar para que el lector sepa cuál es la historia principal que se cuenta. Crear muchos caminos y no esconder adecuadamente los caminos secundarios no es bueno porque estamos dejando en el lector el trabajo de encontrar el *happy path* (lo que no es divertido). Si un lector es incapaz de saber desde un principio cuál es el camino principal de una historia, hemos fallado en algo muy importante.

Otro problema importante es que hay mucho ruido. Si contamos una historia sobre un robot músico que viste una corbata llamado Roboto, y cada vez que queremos referirnos a este robot decimos, literalmente: "Un robot músico que viste una corbata llamado Roboto", vamos a dificultar horriblemente el trabajo del lector. Repetir código es el equivalente a repetir conceptos cuando hablamos o contamos una historia. [La duplicación es una enfermedad rampante](http://blog.8thcolor.com/en/2013/06/duplication-is-a-rampant-disease/).

Un último problema a mencionar es *la presencia de comentarios*. Sí, la presencia de comentarios. Haber usado comentarios significa que no hemos intentado expresarnos usando nuestro lenguaje de programación, sino que hemos fracasado en esa tarea y hemos recurrido a los comentarios para explicar la historia que el código debió haber expresado en un principio. [Los comentarios son siempre fallas](http://www.barebonescoder.com/2011/01/comments-are-always-failures/).

Hay más problemas inherentes a nuestro primer intento de código que explicaré más adelante, detenidamente, patrón por patrón, en otros posts. Escribir código como si fuese una historia no es exactamente un patrón sino un estilo de programación enfocado en la mantenibilidad; en el hecho de que escribimos para otros humanos y, segundo, para la máquina; y en el hecho de que, como humanos, tenemos una predilección a entender más fácilmente las historias que los manuales.

## Un vistazo rápido

Para concluir, dejaré aquí, sin explicar a fondo, el código fuente de una versión refactorizada que, lejos de ser perfecta, trata de explicar una forma distinta de contar la misma historia. Sigue las siguientes reglas:

- No convierte el código en una clase. No es la refactorización que quería mostrar.
- No abstrae mucho la interacción con la API de terceros (Spotify), usando patrones como un mapeador desde la API a algo más abstracto, por la misma razón que la anterior.

En su lugar, se enfoca en mostrar posibles soluciones a algunos importantes problemas de legibilidad como la presencia exagerada de ramas de ejecución o los muchos chequeos de `nil` que se presentan. Tampoco estoy mostrando la implementación del método `Maybe` para dejar un poco de suspenso :)


```ruby
COUNTRY_CODE = ENV['SPOTIFY_COUNTRY_CODE']
USER_ID = ENV['SPOTIFY_USER_ID']

def create_top_ten_playlist_of_artist(artist_name)
  raise "No artist given" if artist_name.blank?

  find_artist_id(artist_name: artist_name) do |artist_id|
    top_tracks_search = spotify.artist_top_tracks(artist_id, COUNTRY_CODE)
    top_tracks = Maybe(top_tracks_search)['tracks'].value || []

    new_playlist_name = "Top Ten : #{artist_name}"
    created_playlist = spotify.create_user_playlist(USER_ID, new_playlist_name)

    track_uris = top_tracks.map { |track| track['uri'] }
    spotify.add_user_tracks_to_playlist(USER_ID, created_playlist['id'], track_uris)
  end
end

def spotify
  @spotify ||= Spotify::Client.new({
    access_token: ENV['SPOTIFY_ACCESS_TOKEN'],
    raise_errors: true
  })
end

def find_artist_id(artist_name: '')
  artists_search = spotify.search(:artist, artist_name)
  artists = Maybe(artists_search)['artists']['items'].value || []

  if artists.any?
    artist_id = Maybe(artists.first)['id'].value
    yield artist_id
  else
    raise "No artist found named #{name}." if artists.empty?
  end
end

create_top_ten_playlist_of_artist(ARGV.first)
```

