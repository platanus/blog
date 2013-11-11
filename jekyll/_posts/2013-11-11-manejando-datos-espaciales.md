---
title: Manejando datos espaciales
author: Leandro Segovia
layout: post/leandro-segovia
categories:
    - rails
    - geoserver
    - spatialdata
    - rgeo
---

Buen día! hago este post con el objeto de mostrarles como trabajar con datos espaciales utilizando:

* [PostgreSQL v9.1.10][1]: como mi base de datos relacional.
* [PostGIS v2.0.2][2]: módulo de PostgreSQL para añadir la funcionalidad que permite trabajar con datos espaciales.
* [Rails v4.0.0][3]: que no necesita presentación :P
* [activerecord-postgis-adapter v0.6.5][4]: gema que permite utilizar RGeo (librería de datos espaciales para Ruby) para extender ActiveRecord con funcionalidad geoespacial.
* [Geoserver v2.4.1][4]: servidor de datos geoespaciales.
* [OpenLayers v2.13.1][5]: librería de javascript para mostrar mapas en los navegadores web.

Mi objetivo no es explicar en profundidad cada una de las herramientas sino, desarrollar de forma básica cada una, para mostrar cómo operan y su potencial.
Por una cuestión de orden, voy a partir el tema en dos secciones:

1. Instalación
2. Ejemplos de funcionamiento + Link a una app de ejemplo.

## Instalación

La explicación será bajo Ubuntu 13.10, así que, por los usuarios de OS X lo lamento y para los de Windows ni siquiera lo lamento. Just kidding! el proceso debería ser incluso más sencillo para Mac/Windows lovers.

Pasos:

1. [Instalar PostgrSQL + PostGIS.][6]
2. [Instalar y configurar Geoserver.][7]
3. Suponiendo que tienen una aplicación corriendo con Rails, añadir las gemas: activerecord-postgis-adapter y [pg][8] (interfaz para postgres) e incluir OpenLayers.
4. Modificar el database.yml agregando `postgis` como `adapter`
5. `rake db:create` creará la base de datos postgres utilizando como template la db template_postgis.
6. Done!

## Ejemplos de funcionamiento

### Crear modelo con datos espaciales

Una vez instalado el adapter, podemos generar un modelo con una columna de tipo geometry (point por ej) de la siguiente manera:

```bash
rails g model client name:string age:integer gender:string salary:decimal the_geom:point
```

que producirá:

```ruby
class CreateClients < ActiveRecord::Migration
  def change
    create_table :clients do |t|
      t.string :name
      t.integer :age
      t.string :gender
      t.decimal :salary
      t.point :the_geom

      t.timestamps
    end
  end
end
```

Luego, indicamos el factory específico que vamos a utilizar en la columna the_geom del modelo Client.

```ruby
class Client < ActiveRecord::Base
  set_rgeo_factory_for_column(:the_geom, RGeo::Geographic.spherical_factory(:srid => 4326))
end
```

Una vez hecho esto, dispondremos de un modelo con capacidad para manejarse con datos espaciales.

### Utilizar las funciones de RGeo

RGeo ofrece una serie de funciones que podemos utilizar para operar con datos espaciales. Como por ej:
crear un buffer, encontrar intersecciones o determinar la distancia entre dos puntos como mostraré a continuación (disponible en la app de ejemplo también)

```ruby
clients = Client.order("random()").limit(2)
c1 = clients.first
c2 = clients.last
puts c1.the_geom.distance(c2.the_geom)
```

En sql el equivalente a buscar la distancia entre dos puntos sería algo como esto:

```ruby
SELECT st_distance(the_geom, ST_GeomFromText('POINT(-72.1235 42.3521)',4326)) FROM clients LIMIT 1
```

### Utilizando OpenLayers

Una de las formas de mostrar datos en un mapa, se puede llevar a cabo obteniendo la informacón de mi servidor, utilizando luego OpenLayers para dibujarla en el cliente. En mi siguiente ejemplo, dibujaré una colección de puntos (json) obtenidos de mi server.

Servicio que devuelve la data:

```ruby
class HomeController < ApplicationController
  def points
    render json: Client.limit(50)
  end
end
```

En mi js...

```javascript
//Creo instancia de map.
mapObject = new OpenLayers.Map({div: "map"});

//Obtengo la data de mi servicio y en la respuesta
$.get("home/points", function(points) {
  var features = []
  //Creo la capa (VectoLayer) donde dibujaré los puntos.
  var vectorLayer = new OpenLayers.Layer.Vector("Vector layer");

  //Recorro los datos, y voy creando los puntos (Feature) en base al gemotery ( attributo the_geom)
  for(var i = 0; i < points.length; i++){
      var geom = new OpenLayers.Geometry.fromWKT(points[i]["the_geom"]);
      var pointFeature = new OpenLayers.Feature.Vector(geom, null, null);
      features.push(pointFeature);
  }

  //Agrego la capa al mapa.
  mapObject.addLayer(vectorLayer);
  //Agrego los puntos a la capa.
  vectorLayer.addFeatures(features);
  //Para redibujar
  vectorLayer.refresh();
});
```

OpenLayers no sólo permite mostrar la información de manera estática, también tiene un amplio soporte para la edición de data, controles para la interacción, manejo de eventos y mucho más.

### WMS con Geoserver

A diferencia de OpenLayers que dibuja features en el cliente (SVG). Geoserver implementa servicios como WMS (Web Map Service) que nos permite obtener la información con formato de imagen (JPEG, PNG, entre otros).
De la misma forma que OpenLayers, Geoserver permite manipular la data aunque en una forma no tan amigable. Aunque, a su favor, permite manejar mayor cantidad de información de manera más eficiente.

Una de las formas de filtrar la información en Geoserver es utilizando cql_filters. Por ej, en la siguiente consulta, pediré a mi layer: geoapp:clientes los puntos que se encuentren dentro del bbox formado por:
`cql_filter: "BBOX(the_geom, 100, 40, -100, -40)"`

```
http://localhost:8080/geoserver/wms?SRS=EPSG:900913&LAYERS=geoapp:clients&FORMAT=image%2Fpng&TILED=true&TRANSPARENT=TRUE&CQL_FILTER=BBOX(the_geom, 100, 40, -100, -40)&SERVICE=WMS&VERSION=1.1.1&REQUEST=GetMap&STYLES=&BBOX=-10018753.83,0.33999999985099,0.33999999985099,10018754.51&WIDTH=256&HEIGHT=256
```

Otra forma, es utilizando rules a través de estilos (SLD). Puedo pasar en mi request el param "styles" con el nombre de algún estilo que defina alguna regla. Por ejemplo podría querer filtrar aquellos clientes que sean hombre. En la aplicación que incluiré, bajo /geoserver/styles puse distintos ejemplos de .sld.
El código de una regla sería como el siguiente:

```
<Rule>
  <Filter>
    <PropertyIsEqualTo>
       <PropertyName>gender</PropertyName>
       <Literal>Hombre</Literal>
    </PropertyIsEqualTo>
  </Filter>
  <Name>rule1</Name>
  <Title>Blue point</Title>
  <Abstract>blue point</Abstract>
    <PointSymbolizer>
      <Graphic>
        <Mark>
          <WellKnownName>square</WellKnownName>
          <Fill>
            <CssParameter name="fill">#1B0BA7</CssParameter>
          </Fill>
        </Mark>
      <Size>6</Size>
    </Graphic>
  </PointSymbolizer>
</Rule>
```

La regla dice que a todos los puntos con el campo "gender" igual a "Hombre" se los coloreará de azul y tendrán un tamaño de 6. Esto también servirá para filtrar si no se ha definido una regla para los casos en los que "gender" sea distinto de "Hombre".

Bueno, esto ha sido todo por hoy. Sientanse libres de [descargar][9] la aplicación de ejemplo que hice donde aplico todas estas herramientas. Recuerden que deberán instalar su entorno como mostré en la primera parte del post y copiar los .sld contenidos en el directorio /geoserver/style en su geoserver.

See ya!

[1]: http://www.postgresql.org/
[2]: http://postgis.net/
[3]: http://rubyonrails.org/
[4]: https://github.com/dazuma/activerecord-postgis-adapter
[5]: http://openlayers.org/
[6]: https://gist.github.com/ldlsegovia/7389724
[7]: https://gist.github.com/ldlsegovia/7389842
[8]: https://github.com/ged/ruby-pg
[9]: https://github.com/platanus/geo-app-demo
