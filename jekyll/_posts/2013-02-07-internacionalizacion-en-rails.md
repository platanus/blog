---
title: Internacionalización en Rails
author: Agustin
layout: post/agustin-feuerhake
categories:
    - rails
    - I18n
---

Es una maravilla.
Lo único que hay que hacer es crear un archivo yaml en config/locales/ (por ejemplo es.yml), poner ahí los strings que queremos traducir, por ejemplo

```yaml
es:
  saludo: "Bienvenido"
  despedida: "Hasta luego!"
```

, y en las vistas hacer algo así

```html
<h1>
  <%=I18n.t 'saludo'%>
</h1>
```

Además, claramente en alguna parte hay que decirle a Rails el idioma que queremos usar. Si queremos simplemente redefinir el default (que obviamente es inglés) basta con agregar la linea

```ruby
config.i18n.default_locale = :es
```

en el archivo config/application.rb
