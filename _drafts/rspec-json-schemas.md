---
layout: post
title: Testeando APIs JSON con JSON Schema
author: emilioeduardob
tags:
  - rspec
  - api
  - rails
  - json
---

Cuando tenemos una API Json en Rails, a medida que la App crece las APIs también van teniendo estructuras más complejas. Para ayudar describir estas APIs vamos a usar `json-schema` y [json_matchers](https://github.com/thoughtbot/json_matchers) de [thoughtbot](https://thoughtbot.com/)

`json-schema` nos permite definir un archivo json con la descripción de que atributos y que tipos de datos deben ser. La estructura del archivo JSON es bastante fácil de aprender. Por ejemplo, para validar que una api devuelve objetos con un atributo `name` tendríamos un archivo asi:

```json
{
  "type": "object",
  "properties": {
    "name": {
      "type": "string"
    }
  }
}
```
Validaría una respuesta de API así:

```json
{
  "name": "Emilio"
}
```

## Refactorizando un test existente

Supongamos que tenemos una API que devuelve el siguiente JSON

```json
{
  "id": "emilioeduardob",
  "bio": "",
  "backdrop": "",
  "avatar": "",
  "video_count": 5,
  "likes": 1,
  "playcount": 198,
  "streams_count": 15,
  "followed": false,
  "name": "Emilio Eduardo Blanco",
  "follower_count": 3,
  "following_count": 1,
  "groups": [
    {"name": "ps4", "gamer_tag": "emilioeduardob"},
    {"name": "xbox", "gamer_tag": "siriuspy"}
  ]
}
```

Para testear esto, podríamos parsear la respuesta y preguntar por los atributos:

```ruby
require 'spec_helper'

describe Api::UsersController do
  describe "GET #show" do
    before do
      @user = create(:user)
      get :show, id: @user.to_param, format: :json
    end

    it "returns success code" do
      expect(response.status).to be(200)
    end

    it "returns correct json structure" do
      parsed_json = JSON.parse(response.body)
      expect(parsed_json["name"]).to eq(@user.name)
      expect(parsed_json["video_count"]).to eq(1)
      expect(parsed_json["likes"]).to eq(1)
      expect(parsed_json["follower_count"]).to eq(0)
      expect(parsed_json["following_count"]).to eq(0)
    end

    it "includes group information" do
      group_json = JSON.parse(response.body)["groups"]
      expect(group_json[0]["name"]).to eq("ps4")
      expect(group_json[0]["gamer_tag"]).to eq("emilioeduardob")
    end
  end

  describe "PUT #update" do
    before do
      @user = create(:user)
      put :update, id: @user.to_param, name: "Sirius", format: :json
    end

    it "returns success code" do
      expect(response.status).to be(200)
    end

    it "returns the json object" do
      parsed_json = JSON.parse(response.body)
      expect(parsed_json["name"]).to eq("Sirius")
      expect(parsed_json["video_count"]).to eq(1)
      expect(parsed_json["likes"]).to eq(1)
      expect(parsed_json["follower_count"]).to eq(0)
      expect(parsed_json["following_count"]).to eq(0)
    end
  end
```  

## Refactor utilizando `json-schema`

Instalamos la gema

```ruby
group :test do
  gem "json_matchers"
end
```

Y agregamos el `require` al `spec_helper` para poder tener el helper `match_response_schema` que nos provee la gema `json_matchers`.

Luego de seguir los pasos de [instalación](https://github.com/thoughtbot/json_matchers#installation)
Agregamos la definición del schema para el objeto `user`

### spec/support/api/schemas/user.json

```json

{
  "type": "object",
  "properties": {
    "id": {
      "type": "string"
    },
    "username": {
      "type": "string"
    },
    "bio": {
      "type": "string"
    },
    "backdrop": {
      "type": ["string", "null"]
    },
    "avatar": {
      "type": "string"
    },
    "video_count": {
      "type": "integer"
    },
    "likes": {
      "type": "integer"
    },
    "playcount": {
      "type": "integer"
    },
    "streams_count": {
      "type": "integer"
    },
    "followed": {
      "type": "boolean"
    },
    "name": {
      "type": "string"
    },
    "follower_count": {
      "type": "integer"
    },
    "following_count": {
      "type": "integer"
    },
    "groups": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "name": {
            "type": "string"
          },
          "gamer_tag": {
            "type": "string"
          }
        },
        "required": [
          "name",
          "gamer_tag"
        ]
      }
    }
  }
}
```

```ruby
require 'spec_helper'

describe Api::UsersController do
  describe "GET #show" do
    before do
      @user = create(:user)
      get :show, id: @user.to_param, format: :json
    end

    it "returns success code" do
      expect(response.status).to be(200)
    end

    it "returns correct json structure" do
      expect(response).to match_response_schema("user")
    end
  end

  describe "PUT #update" do
    before do
      @user = create(:user)
      put :update, id: @user.to_param, name: "Sirius", format: :json
    end

    it "returns success code" do
      expect(response.status).to be(200)
    end

    it "returns correct json structure" do
      expect(response).to match_response_schema("user")
    end
  end
```  

## Refactorizando schema json

Como vemos, la definición de user incluye objetos `group`, podemos separar esto en su propio archivo.

### spec/support/api/schemas/group.json

```json
{
  "type": "object",
  "properties": {
    "name": {
      "type": "string"
    },
    "gamer_tag": {
      "type": "string"
    }
  }
}
```

Luego la definición de un `user` quedaría asi:

```json

{
  "type": "object",
  "properties": {
    "id": {
      "type": "string"
    },
    "username": {
      "type": "string"
    },
    "bio": {
      "type": "string"
    },
    "backdrop": {
      "type": "string"
    },
    "avatar": {
      "type": "string"
    },
    "video_count": {
      "type": "integer"
    },
    "likes": {
      "type": "integer"
    },
    "playcount": {
      "type": "integer"
    },
    "streams_count": {
      "type": "integer"
    },
    "followed": {
      "type": "boolean"
    },
    "name": {
      "type": "string"
    },
    "follower_count": {
      "type": "integer"
    },
    "following_count": {
      "type": "integer"
    },
    "groups": {
      "type": "array",
      "items": { "$ref": "group.json" }
    }
  }
}
```

Un detalle, seguro dirán que es muy tedioso escribir los archivos de schema, pero por suerte pueden ser generados [JSONSchema.net](http://jsonschema.net/
