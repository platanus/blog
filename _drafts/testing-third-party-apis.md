---
layout: post
title: ¿Cómo probamos las APIs de terceros?
author: arturopuente
tags:
  - rails
  - testing
  - api
  - third-party
---

Un problema común que nos encontramos al testear nuestras aplicaciones es la integración con servicios de terceros.

Enviar los requests a las APIs de terceros en cada test tiene varios problemas:

- Nos topamos con el límite de requests en un determinado tiempo
- Los tests pueden fallar por problemas de conexión
- La suite de pruebas demora **mucho**

Hay gemas que nos ayudan que nuestras pruebas funcionen mejor, por ejemplo:

- **[Webmock](https://github.com/bblimke/webmock)** desactiva los requests a cualquier servicio externo e ir devolviendo respuestas predeterminadas por cada URL.

- **[VCR](https://github.com/vcr/vcr)** ejecuta nuestros tests una vez contra los servicios reales y guarda las respuestas en un JSON (cassettes), de forma que la siguiente vez que la suite se ejecute ese JSON servirá para mockear la respuesta del servidor.

Sin embargo, todas estas gemas añaden una capa de complejidad a nuestra suite:

- Con Webmock si queremos que hacer requests a un servicio de terceros en una prueba tenemos que manejar manualmente la activación/desactivación de los requests externos

- Al usar VCR tenemos que manejar los cassettes y como contienen toda la interacción entre los servidores, manipularlos y editarlos es más complejo y tedioso.

¿Qué alternativa tenemos entonces? Me parece que la respuesta está en usar RSpec hasta que la complejidad de nuestra suite nos obligue a buscar una gema adicional, así evitamos añadir una dependencia más y evitamos los problemas/workarounds que las otras gemas traen consigo.

## Usando RSpec para mockear servicios externos

Empecemos por hacer un bosquejo rápido de la arquitectura de una aplicación:

- Tenemos un servicio `ReachCalculator` que recibe un conjunto de tweets y calcula el alcance que un hashtag está teniendo en determinado momento.
- Los resultados de este cálculo se guarda en el modelo `Reach`.
- Adicionalmente, existe el servicio `TwitterService` que interactúa con la API de Twitter directamente y le devuelve al `ReachCalculator` un JSON.

Empecemos con `TwitterService`:

```ruby
class TwitterService

  API_KEY = ENV["TWITTER_API_KEY"]
  SEARCH_URL = "https://api.twitter.com/1.1/search/tweets.json?q="

  def search_hashtag(hashtag)
    make_external_request_for(SEARCH_URL + hashtag)
  end

  private

  def make_external_request_for(url)
    Net::HTTP.get(url)
  end
end
```

Vamos a ver cómo serían las pruebas de este servicio si no usáramos mocking en RSpec:

```ruby
require 'spec_helper'

describe TwitterService do
  let(:service) { described_class.new }

  it "should send requests to Twitter" do
    expect(service.search_hashtag("#ruby").size).to eq(200)
  end
end
```

Aquí vemos claramente que estamos procesando un request gigante sólo para probar que funcione la conexión con Twitter, puesto que la validación del formato correctodebería ir en el `ReachCalculator`. Por suerte usando un mock de RSpec podemos mejorar este test de forma muy simple:


```ruby
require 'spec_helper'

describe TwitterService do
  let(:service) { described_class.new }

  before do
    allow(service).to receive(:search_hashtag).and_return([
      {
        "tweet_id": "1341094104",
        "user_id": "1401401940",
        "favorite_count": "257",
        "retweet_count": "834",
        "created_at": "Wed Aug 27 13:08:45 +0000 2008"
      }
    ])
  end

  it "should send requests to Twitter" do
    expect(service.search_hashtag("#ruby").size).to eq(1)
  end
end
```

Esta prueba se ejecuta mucho más rápido, y nos olvidamos de los problemas de lidiar con servicios externos. En el argumento que le enviamos en `and_return` podemos poner el JSON que queremos probar, o un subset de este JSON (lo que realmente nos interese probar en cada contexto). Podemos incluso guardarlo en archivos aparte, pero mantenemos la flexibilidad de no estar atados a usarlos siempre.
